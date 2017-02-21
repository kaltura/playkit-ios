//
//  YouboraPlugin.swift
//  AdvancedExample
//
//  Created by Oded Klein on 19/10/2016.
//  Copyright © 2016 Kaltura, Inc. All rights reserved.
//

import YouboraLib
import YouboraPluginAVPlayer
import AVFoundation

/// `YouboraPluginError` represents youbora plugin errors.
enum YouboraPluginError: PKError {
    
    case failedToSetupYouboraManager
    
    static let Domain = PKErrorDomain.Youbora
    
    var code: Int {
        switch self {
        case .failedToSetupYouboraManager: return 3000
        }
    }
    
    var errorDescription: String {
        switch self {
        case .failedToSetupYouboraManager: return "failed to setup youbora manager, missing config/config params or mediaEntry"
        }
    }
    
    var userInfo: [String: Any] {
        switch self {
        case .failedToSetupYouboraManager: return [:]
        }
    }
}

public class YouboraPlugin: BaseAnalyticsPlugin {
    
    public override class var pluginName: String {
        return "YouboraPlugin"
    }
    
    private var youboraManager : YouboraManager?
    
    /************************************************************/
    // MARK: - PKPlugin
    /************************************************************/
    
    public override func onLoad(mediaConfig: MediaConfig) {
        super.onLoad(mediaConfig: mediaConfig)
        self.setupYouboraManager() { succeeded in
            if succeeded {
                self.startMonitoring(player: self.player)
            }
        }
    }
    
    public override func onUpdateMedia(mediaConfig: MediaConfig) {
        super.onUpdateMedia(mediaConfig: mediaConfig)
        self.setupYouboraManager()
    }
    
    public override func destroy() {
        super.destroy()
        self.stopMonitoring()
    }
    
    /************************************************************/
    // MARK: - AnalytisPluginProtocol
    /************************************************************/
    
    override var playerEventsToRegister: [PlayerEvent.Type] {
        return [
            PlayerEvent.canPlay,
            PlayerEvent.play,
            PlayerEvent.pause,
            PlayerEvent.playing,
            PlayerEvent.seeking,
            PlayerEvent.seeked,
            PlayerEvent.ended,
            PlayerEvent.playbackParamsUpdated,
            PlayerEvent.stateChanged
        ]
    }
    
    override func registerEvents() {
        PKLog.debug("register player events")
        
        self.playerEventsToRegister.forEach { event in
            PKLog.debug("Register event: \(event.self)")
            
            switch event {
            case let e where e.self == PlayerEvent.canPlay:
                self.messageBus.addObserver(self, events: [e.self]) { [unowned self] event in
                    self.postEventLogWithMessage(message: "canPlay event: \(event)")
                }
            case let e where e.self == PlayerEvent.play:
                self.messageBus.addObserver(self, events: [e.self]) { [unowned self] event in
                    guard let youboraManager = self.youboraManager else { return }
                    youboraManager.playHandler()
                    self.postEventLogWithMessage(message: "play event: \(event)")
                }
            case let e where e.self == PlayerEvent.pause:
                self.messageBus.addObserver(self, events: [e.self]) { [unowned self] event in
                    guard let youboraManager = self.youboraManager else { return }
                    youboraManager.pauseHandler()
                    self.postEventLogWithMessage(message: "pause event: \(event)")
                }
            case let e where e.self == PlayerEvent.playing:
                self.messageBus.addObserver(self, events: [e.self]) { [unowned self] event in
                    self.postEventLogWithMessage(message: "playing event: \(event)")
                    
                    guard let youboraManager = self.youboraManager else { return }
                    
                    if self.isFirstPlay {
                        youboraManager.joinHandler()
                        youboraManager.bufferedHandler()
                        self.isFirstPlay = false
                    } else {
                        youboraManager.resumeHandler()
                    }
                }
            case let e where e.self == PlayerEvent.seeking:
                self.messageBus.addObserver(self, events: [e.self]) { [unowned self] event in
                    guard let youboraManager = self.youboraManager else { return }
                    youboraManager.seekingHandler()
                    self.postEventLogWithMessage(message: "seeking event: \(event)")
                }
            case let e where e.self == PlayerEvent.seeked:
                self.messageBus.addObserver(self, events: [e.self]) { [unowned self] (event) in
                    guard let youboraManager = self.youboraManager else { return }
                    youboraManager.seekedHandler()
                    self.postEventLogWithMessage(message: "seeked event: \(event)")
                }
            case let e where e.self == PlayerEvent.ended:
                self.messageBus.addObserver(self, events: [e.self]) { [unowned self] (event) in
                    guard let youboraManager = self.youboraManager else { return }
                    youboraManager.endedHandler()
                    self.postEventLogWithMessage(message: "ended event: \(event)")
                }
            case let e where e.self == PlayerEvent.playbackParamsUpdated:
                self.messageBus.addObserver(self, events: [e.self]) { [unowned self] (event) in
                    guard let youboraManager = self.youboraManager else { return }
                    youboraManager.currentBitrate = event.currentBitrate?.doubleValue
                    self.postEventLogWithMessage(message: "playbackParamsUpdated event: \(event)")
                }
            case let e where e.self == PlayerEvent.stateChanged:
                self.messageBus.addObserver(self, events: [e.self]) { [unowned self] (event) in
                    guard let youboraManager = self.youboraManager else { return }
                    if let stateChanged = event as? PlayerEvent.StateChanged {
                        switch event.newState {
                        case .buffering:
                            youboraManager.bufferingHandler()
                            self.postEventLogWithMessage(message: "Buffering event: ֿ\(event)")
                            break
                        default: break
                        }
                        
                        switch event.oldState {
                        case .buffering:
                            youboraManager.bufferedHandler()
                            self.postEventLogWithMessage(message: "Buffered event: \(event)")
                            break
                        default: break
                        }
                    }
                }
            default: assertionFailure("all events must be handled")
            }
        }
        
        PKLog.debug("register ads events")
        self.messageBus.addObserver(self, events: AdEvent.allEventTypes) { [unowned self] (event) in
            self.postEventLogWithMessage(message: "Ads event event: \(event)")
        }
    }
    
    /************************************************************/
    // MARK: - Private
    /************************************************************/
    
    private func setupYouboraManager(completionHandler: ((_ succeeded: Bool) -> Void)? = nil) {
        if let config = self.config, var media = config.params["media"] as? [String: Any], let mediaEntry = self.mediaEntry {
            media["resource"] = mediaEntry.id
            media["title"] = mediaEntry.id
            media["duration"] = self.player.duration
            config.params["media"] = media
            youboraManager = YouboraManager(options: config.params as NSObject!, player: player, mediaEntry: mediaEntry)
            completionHandler?(true)
        } else {
            PKLog.error("config params are wrong or doesn't exist, or missing MediaEntry, could not setup youbora manager")
            self.messageBus.post(PlayerEvent.PluginError(nsError: YouboraPluginError.failedToSetupYouboraManager.asNSError))
            completionHandler?(false)
        }
    }
    
    private func startMonitoring(player: Player) {
        guard let youboraManager = self.youboraManager else { return }
        PKLog.debug("Start monitoring using Youbora")
        youboraManager.startMonitoring(withPlayer: youboraManager)
    }
    
    private func stopMonitoring() {
        guard let youboraManager = self.youboraManager else { return }
        PKLog.debug("Stop monitoring using Youbora")
        youboraManager.stopMonitoring()
    }
    
    private func postEventLogWithMessage(message: String) {
        PKLog.debug(message)
        let eventLog = YouboraEvent.YouboraReportSent(message: message as NSString)
        self.messageBus.post(eventLog)
    }
}

