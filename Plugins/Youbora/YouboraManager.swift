//
//  YouboraManager.swift
//  Pods
//
//  Created by Oded Klein on 28/11/2016.
//
//

import YouboraLib
import YouboraPluginAVPlayer
import Foundation
import UIKit
import AVFoundation
import AVKit

class YouboraManager: YBPluginGeneric {

    fileprivate weak var pkPlayer: Player?
    var lastReportedBitrate: Double?
    var lastReportedResource: String?
    
    fileprivate weak var messageBus: MessageBus?
    
    /// indicates whether we played for the first time or not.
    fileprivate var isFirstPlay: Bool = true
    
    /// Indicates if we have to delay the endedHandler() (for example when we have post-roll).
    fileprivate var shouldDelayEndedHandler = false
    
    init(options: NSObject!, player: Player) {
        super.init(options: options)
        self.pluginVersion = YBYouboraLibVersion + "-" + PlayKitManager.clientTag // TODO: put plugin version when we will seperate
        self.pkPlayer = player
    }
    
    // we must override this init in order to add our init (happens because of interopatability of youbora objc framework with swift). 
    private override init() {
        super.init()
    }
}

/************************************************************/
// MARK: - Youbora PluginGeneric
/************************************************************/

extension YouboraManager {
    
    override func startMonitoring(withPlayer player: NSObject!) {
        guard let messageBus = player as? MessageBus else {
            assertionFailure("our events handler object must be of type: `MessageBus`")
            return
        }
        super.startMonitoring(withPlayer: nil) // no need to pass our object it is not player type
        self.reset()
        self.messageBus = messageBus
        self.registerEvents(onMessageBus: messageBus)
    }
    
    override func stopMonitoring() {
        if let messageBus = self.messageBus {
            self.unregisterEvents(fromMessageBus: messageBus)
        }
        super.stopMonitoring()
    }
}

/************************************************************/
// MARK: - Youbora Info Methods
/************************************************************/

extension YouboraManager {
    
    override func getMediaDuration() -> NSNumber! {
        let duration = self.pkPlayer?.duration
        return duration != nil ? NSNumber(value: duration!) : super.getMediaDuration()
    }
    
    override func getResource() -> String! {
        return self.lastReportedResource ?? super.getResource() // FIXME: make sure to expose player content url and use it here instead of id
    }
    
    override func getTitle() -> String! {
        return self.pkPlayer?.mediaEntry?.id ?? super.getTitle()
    }
    
    override func getPlayhead() -> NSNumber! {
        let currentTime = self.pkPlayer?.currentTime
        return currentTime != nil ? NSNumber(value: currentTime!) : super.getPlayhead()
    }
    
    override func getPlayerVersion() -> String! {
        return "\(PlayKitManager.clientTag)"
    }
    
    override func getBitrate() -> NSNumber! {
        if let bitrate = lastReportedBitrate {
            return NSNumber(value: bitrate)
        }
        return super.getBitrate()
    }
}

/************************************************************/
// MARK: - Events Handling
/************************************************************/

extension YouboraManager {
    
    private var eventsToRegister: [PKEvent.Type] {
        return [
            PlayerEvent.play,
            PlayerEvent.stopped,
            PlayerEvent.pause,
            PlayerEvent.playing,
            PlayerEvent.seeking,
            PlayerEvent.seeked,
            //PlayerEvent.ended, FIXME: check with youbora if needed
            PlayerEvent.playbackParamsUpdated,
            PlayerEvent.stateChanged,
            AdEvent.adCuePointsUpdate,
            AdEvent.allAdsCompleted
        ]
    }
    
    fileprivate func registerEvents(onMessageBus messageBus: MessageBus) {
        PKLog.debug("register events")
        
        self.eventsToRegister.forEach { event in
            PKLog.debug("Register event: \(event.self)")
            
            switch event {
            case let e where e.self == PlayerEvent.play:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    // play handler to start when asset starts loading.
                    // this point is the closest point to prepare call.
                    strongSelf.playHandler()
                    strongSelf.postEventLogWithMessage(message: "\(type(of: event))")
                }
            case let e where e.self == PlayerEvent.stopped:
                self.messageBus?.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    // we must call `endedHandler()` when stopped so youbora will know player stopped playing content.
                    strongSelf.adnalyzer.endedAdHandler()
                    strongSelf.endedHandler()
                    strongSelf.postEventLogWithMessage(message: "\(type(of: event))")
                }
            case let e where e.self == PlayerEvent.pause:
                self.messageBus?.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    strongSelf.pauseHandler()
                    strongSelf.postEventLogWithMessage(message: "\(type(of: event))")
                }
            case let e where e.self == PlayerEvent.playing:
                self.messageBus?.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    if strongSelf.isFirstPlay {
                        strongSelf.isFirstPlay = false
                        strongSelf.joinHandler()
                        strongSelf.bufferedHandler()
                    } else {
                        strongSelf.resumeHandler()
                    }
                    strongSelf.postEventLogWithMessage(message: "\(String(describing: type(of: event)))")
                }
            case let e where e.self == PlayerEvent.seeking:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    strongSelf.seekingHandler()
                    strongSelf.postEventLogWithMessage(message: "\(type(of: event))")
                }
            case let e where e.self == PlayerEvent.seeked:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    strongSelf.seekedHandler()
                    strongSelf.postEventLogWithMessage(message: "\(type(of: event))")
                }
                // FIXME: check with youbora if needed
            /*case let e where e.self == PlayerEvent.ended:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    if !strongSelf.shouldDelayEndedHandler {
                        strongSelf.endedHandler()
                    }
                    strongSelf.postEventLogWithMessage(message: "\(type(of: event))")
                }*/
            case let e where e.self == PlayerEvent.playbackParamsUpdated:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    strongSelf.lastReportedBitrate = event.currentBitrate?.doubleValue
                    strongSelf.postEventLogWithMessage(message: "\(type(of: event))")
                }
            case let e where e.self == PlayerEvent.stateChanged:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    if event.newState == .buffering {
                        strongSelf.bufferingHandler()
                        strongSelf.postEventLogWithMessage(message: "\(type(of: event))")
                    } else if event.oldState == .buffering {
                        strongSelf.bufferedHandler()
                        strongSelf.postEventLogWithMessage(message: "\(type(of: event))")
                    }
                }
            case let e where e.self == AdEvent.adCuePointsUpdate:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    if let hasPostRoll = event.adCuePoints?.hasPostRoll, hasPostRoll == true {
                        self?.shouldDelayEndedHandler = true
                    }
                }
            case let e where e.self == AdEvent.allAdsCompleted:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    if let shouldDelayEndedHandler = self?.shouldDelayEndedHandler, shouldDelayEndedHandler == true {
                        self?.shouldDelayEndedHandler = false
                        self?.adnalyzer.endedAdHandler()
                    }
                }
            default: assertionFailure("all events must be handled")
            }
        }
    }
    
    fileprivate func unregisterEvents(fromMessageBus messageBus: MessageBus) {
        messageBus.removeObserver(self, events: eventsToRegister)
    }
}

/************************************************************/
// MARK: - Internal
/************************************************************/

extension YouboraManager {
    
    func reset() {
        self.lastReportedBitrate = nil
        self.lastReportedResource = nil
        self.isFirstPlay = true
        self.shouldDelayEndedHandler = false
    }
}

/************************************************************/
// MARK: - Private
/************************************************************/

extension YouboraManager {
    
    fileprivate func postEventLogWithMessage(message: String) {
        let eventLog = YouboraEvent.Report(message: message)
        self.messageBus?.post(eventLog)
    }
}
