//
//  BaseOTTAnalyticsPlugin.swift
//  Pods
//
//  Created by Gal Orlanczyk on 06/02/2017.
//
//

import Foundation

/// class `BaseOTTAnalyticsPlugin` is a base plugin object used for OTT analytics plugin subclasses
public class BaseOTTAnalyticsPlugin: BaseAnalyticsPlugin, OTTAnalyticsPluginProtocol, AppStateObservable {
    
    var intervalOn: Bool = false
    var timer: Timer?
    var interval: TimeInterval = 30
    
    /************************************************************/
    // MARK: - PKPlugin
    /************************************************************/
    
    public override func onLoad(mediaConfig: MediaConfig) {
        super.onLoad(mediaConfig: mediaConfig)
        AppStateSubject.shared.add(observer: self)
    }
    
    public override func onUpdateMedia(mediaConfig: MediaConfig) {
        super.onUpdateMedia(mediaConfig: mediaConfig)
        AppStateSubject.shared.add(observer: self)
    }
    
    public override func destroy() {
        super.destroy()
        self.sendAnalyticsEvent(ofType: .stop)
        self.stopTimer()
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
            PlayerEvent.playing
        ]
    }
    
    override func registerEvents() {
        PKLog.debug("plugin \(type(of:self)) register to all player events")
        
        self.playerEventsToRegister.forEach { event in
            PKLog.debug("Register event: \(event.self)")
            
            switch event {
            case let e where e.self == PlayerEvent.ended:
                self.messageBus.addObserver(self, events: [e.self], block: { event in
                    PKLog.debug("ended event: \(event)")
                    self.stopTimer()
                    self.sendAnalyticsEvent(ofType: .finish)
                })
            case let e where e.self == PlayerEvent.error:
                self.messageBus.addObserver(self, events: [e.self], block: { event in
                    PKLog.debug("error event: \(event)")
                    self.sendAnalyticsEvent(ofType: .error)
                })
            case let e where e.self == PlayerEvent.pause:
                self.messageBus.addObserver(self, events: [e.self], block: { event in
                    PKLog.debug("pause event: \(event)")
                    // invalidate timer when receiving pause event only after first play
                    // and set intervalOn to false in order to start timer again on play event.
                    if !self.isFirstPlay {
                        self.stopTimer()
                        self.intervalOn = false
                    }
                    
                    self.sendAnalyticsEvent(ofType: .pause)
                })
            case let e where e.self == PlayerEvent.loadedMetadata:
                self.messageBus.addObserver(self, events: [e.self], block: { event in
                    PKLog.debug("loadedMetadata event: \(event)")
                    self.sendAnalyticsEvent(ofType: .load)
                })
            case let e where e.self == PlayerEvent.playing:
                self.messageBus.addObserver(self, events: [e.self], block: { event in
                    PKLog.debug("play event: \(event)")
                    
                    if !self.intervalOn {
                        self.createTimer()
                        self.intervalOn = true
                    }
                    
                    if self.isFirstPlay {
                        self.isFirstPlay = false
                        self.sendAnalyticsEvent(ofType: .first_play);
                    } else {
                        self.sendAnalyticsEvent(ofType: .play);
                    }
                })
            default: assertionFailure("plugin \(type(of:self)) all events must be handled")
            }
        }
    }
    
    /************************************************************/
    // MARK: - OTTAnalyticsPluginProtocol
    /************************************************************/
    
    func sendAnalyticsEvent(ofType type: OTTAnalyticsEventType) {
        PKLog.debug("Send analytics event of type: \(type)")
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
        self.messageBus.post(OttEvent.Concurrency())
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
    
    fileprivate func stopTimer() {
        if let t = self.timer {
            t.invalidate()
        }
    }
    
    fileprivate func sendProgressEvent() {
        self.sendAnalyticsEvent(ofType: .hit);
        
        let progress = Float(self.player.currentTime) / Float(self.player.duration)
        PKLog.debug("Progress is \(progress)")
        
        if progress > 0.98 {
            self.sendAnalyticsEvent(ofType: .finish)
        }
    }
}




