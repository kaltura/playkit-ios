//
//  BaseOTTAnalyticsPlugin.swift
//  Pods
//
//  Created by Gal Orlanczyk on 06/02/2017.
//
//

import Foundation
import KalturaNetKit

/// class `BaseOTTAnalyticsPlugin` is a base plugin object used for OTT analytics plugin subclasses
public class BaseOTTAnalyticsPlugin: BaseAnalyticsPlugin, OTTAnalyticsPluginProtocol, AppStateObservable {
    
    var intervalOn: Bool = false
    var timer: Timer?
    var interval: TimeInterval = 30
    var isContentEnded: Bool = false
    
    /************************************************************/
    // MARK: - PKPlugin
    /************************************************************/
    
    public required init(player: Player, pluginConfig: Any?, messageBus: MessageBus) throws {
        try super.init(player: player, pluginConfig: pluginConfig, messageBus: messageBus)
        AppStateSubject.shared.add(observer: self)
    }

    public override func onUpdateMedia(mediaConfig: MediaConfig) {
        super.onUpdateMedia(mediaConfig: mediaConfig)
        self.intervalOn = false
        self.isContentEnded = false
        self.timer?.invalidate()
    }
    
    public override func destroy() {
        super.destroy()
        // only send stop event if content started playing already & content is not ended
        if !self.isFirstPlay && !self.isContentEnded {
            self.sendAnalyticsEvent(ofType: .stop)
        }
        self.timer?.invalidate()
        AppStateSubject.shared.remove(observer: self)
    }
    
    /************************************************************/
    // MARK: - App State Handling
    /************************************************************/
    
    var observations: Set<NotificationObservation> {
        return [
            NotificationObservation(name: .UIApplicationWillTerminate) { [unowned self] in
                PKLog.debug("plugin: \(self) will terminate event received, sending analytics stop event")
                self.destroy()
            }
        ]
    }
    
    /************************************************************/
    // MARK: - AnalyticsPluginProtocol
    /************************************************************/
    
    /// default events to register
    override var playerEventsToRegister: [PlayerEvent.Type] {
        return [
            PlayerEvent.ended,
            PlayerEvent.error,
            PlayerEvent.pause,
            PlayerEvent.loadedMetadata,
            PlayerEvent.playing,
            PlayerEvent.seeked
        ]
    }
    
    override func registerEvents() {
        PKLog.debug("plugin \(type(of:self)) register to all player events")
        
        self.playerEventsToRegister.forEach { event in
            PKLog.debug("Register event: \(event.self)")
            
            switch event {
            case let e where e.self == PlayerEvent.seeked: strongSelf.isContentEnded = false
            case let e where e.self == PlayerEvent.ended:
                self.messageBus?.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    PKLog.debug("ended event: \(event)")
                    strongSelf.timer?.invalidate()
                    strongSelf.sendAnalyticsEvent(ofType: .finish)
                    strongSelf.isContentEnded = true
                }
            case let e where e.self == PlayerEvent.error:
                self.messageBus?.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    PKLog.debug("error event: \(event)")
                    strongSelf.sendAnalyticsEvent(ofType: .error)
                }
            case let e where e.self == PlayerEvent.pause:
                self.messageBus?.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    PKLog.debug("pause event: \(event)")
                    // invalidate timer when receiving pause event only after first play
                    // and set intervalOn to false in order to start timer again on play event.
                    if !strongSelf.isFirstPlay {
                        strongSelf.timer?.invalidate()
                        strongSelf.intervalOn = false
                    }
                    strongSelf.sendAnalyticsEvent(ofType: .pause)
                }
            case let e where e.self == PlayerEvent.loadedMetadata:
                self.messageBus?.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    PKLog.debug("loadedMetadata event: \(event)")
                    strongSelf.sendAnalyticsEvent(ofType: .load)
                }
            case let e where e.self == PlayerEvent.playing:
                self.messageBus?.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    PKLog.debug("play event: \(event)")
                    
                    if !strongSelf.intervalOn {
                        strongSelf.createTimer()
                        strongSelf.intervalOn = true
                    }
                    
                    if strongSelf.isFirstPlay {
                        strongSelf.isFirstPlay = false
                        strongSelf.sendAnalyticsEvent(ofType: .first_play);
                    } else {
                        strongSelf.sendAnalyticsEvent(ofType: .play);
                    }
                }
            default: assertionFailure("plugin \(type(of:self)) all events must be handled")
            }
        }
    }
    
    /************************************************************/
    // MARK: - OTTAnalyticsPluginProtocol
    /************************************************************/
    
    func sendAnalyticsEvent(ofType type: OTTAnalyticsEventType) {
        PKLog.debug("Send analytics event of type: \(type)")
        // post to messageBus
        let event = OttEvent.Report(message: "\(type) event")
        self.messageBus?.post(event)
        
        if let request = self.buildRequest(ofType: type) {
            self.send(request: request)
        }
    }
    
    func buildRequest(ofType type: OTTAnalyticsEventType) -> Request? {
        fatalError("abstract method should be implemented in subclasses only")
    }
    
    func send(request: Request) {
        USRExecutor.shared.send(request: request)
    }
    
    /************************************************************/
    // MARK: - Internal
    /************************************************************/
    
    func reportConcurrencyEvent() {
        self.messageBus?.post(OttEvent.Concurrency())
    }
}

/************************************************************/
// MARK: - Private
/************************************************************/

extension BaseOTTAnalyticsPlugin {
    
    fileprivate func createTimer() {
        if let conf = self.config, let intr = conf.params["timerInterval"] as? TimeInterval {
            self.interval = intr
        }
        
        if let t = self.timer {
            t.invalidate()
        }
        
        // media hit should fire on every time we start the timer.
        self.sendProgressEvent()
        
        self.timer = Timer.every(self.interval) { [unowned self] in
            PKLog.debug("timerHit")
            self.sendProgressEvent()
        }
    }
    
    fileprivate func sendProgressEvent() {
        guard let player = self.player else { return }
        self.sendAnalyticsEvent(ofType: .hit);
        
        let progress = Float(player.currentTime) / Float(player.duration)
        PKLog.debug("Progress is \(progress)")
        
        if progress > 0.98 {
            self.sendAnalyticsEvent(ofType: .finish)
        }
    }
}




