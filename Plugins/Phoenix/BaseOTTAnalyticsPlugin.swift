//
//  BaseOTTAnalyticsPlugin.swift
//  Pods
//
//  Created by Gal Orlanczyk on 06/02/2017.
//
//

import Foundation

/// class `BaseOTTAnalyticsPlugin` is a base plugin object used for OTT analytics plugin subclasses
public class BaseOTTAnalyticsPlugin: KalturaOTTAnalyticsPluginProtocol, AppStateObservable {
    
    /// abstract implementation subclasses will have names
    public class var pluginName: String {
        fatalError("abstract property should be implemented in subclasses only")
    }
    
    unowned var player: Player
    unowned var messageBus: MessageBus
    public weak var mediaEntry: MediaEntry?
    
    var config: AnalyticsConfig?
    
    var isFirstPlay: Bool = true
    var intervalOn: Bool = false
    var timer: Timer?
    var interval: TimeInterval = 30
    
    /************************************************************/
    // MARK: - PKPlugin
    /************************************************************/
    
    public required init(player: Player, pluginConfig: Any?, messageBus: MessageBus) {
        self.player = player
        self.messageBus = messageBus
        if let aConfig = pluginConfig as? AnalyticsConfig {
            self.config = aConfig
        }
        self.registerEvents()
    }
    
    public func onLoad(mediaConfig: MediaConfig) {
        PKLog.trace("plugin \(type(of:self)) onLoad with media config: \(mediaConfig)")
        self.mediaEntry = mediaConfig.mediaEntry
        AppStateSubject.shared.add(observer: self)
    }
    
    public func onUpdateMedia(mediaConfig: MediaConfig) {
        PKLog.trace("plugin \(type(of:self)) onUpdateMedia with media config: \(mediaConfig)")
        self.mediaEntry = mediaConfig.mediaEntry
        AppStateSubject.shared.add(observer: self)
    }
    
    public func destroy() {
        self.sendAnalyticsEvent(ofType: .stop)
        self.stopTimer()
        self.messageBus.removeObserver(self, events: playerEventsToRegister)
        AppStateSubject.shared.remove(observer: self)
    }
    
    /************************************************************/
    // MARK: - App State Handling
    /************************************************************/
    
    var observations: Set<NotificationObservation> {
        return [
            NotificationObservation(name: .UIApplicationWillTerminate) { [unowned self] in
                PKLog.trace("plugin: \(self) will terminate event received, sending analytics stop event")
                self.destroy()
            }
        ]
    }
    
    /************************************************************/
    // MARK: - KalturaAnalyticsPluginProtocol
    /************************************************************/
    
    /// default events to register
    var playerEventsToRegister: [PlayerEvent.Type] {
        return [
            PlayerEvent.ended,
            PlayerEvent.error,
            PlayerEvent.pause,
            PlayerEvent.loadedMetadata,
            PlayerEvent.playing
        ]
    }
    
    /************************************************************/
    // MARK: - KalturaOTTAnalyticsPluginProtocol
    /************************************************************/
    
    func sendAnalyticsEvent(ofType type: OTTAnalyticsEventType) {
        PKLog.trace("Event type: \(type)")
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
    
    func registerEvents() {
        PKLog.trace("Register to all player events")
        
        self.playerEventsToRegister.forEach { event in
            PKLog.debug("Register event: \(event.self)")
            
            switch event {
            case let e where e.self == PlayerEvent.ended:
                self.messageBus.addObserver(self, events: [PlayerEvent.ended], block: { event in
                    PKLog.trace("ended info: \(event)")
                    self.stopTimer()
                    self.sendAnalyticsEvent(ofType: .finish)
                })
            case let e where e.self == PlayerEvent.error:
                self.messageBus.addObserver(self, events: [PlayerEvent.error], block: { event in
                    PKLog.trace("error info: \(event)")
                    self.sendAnalyticsEvent(ofType: .error)
                })
            case let e where e.self == PlayerEvent.pause:
                self.messageBus.addObserver(self, events: [PlayerEvent.pause], block: { event in
                    PKLog.trace("pause info: \(event)")
                    self.sendAnalyticsEvent(ofType: .pause)
                })
            case let e where e.self == PlayerEvent.loadedMetadata:
                self.messageBus.addObserver(self, events: [PlayerEvent.loadedMetadata], block: { event in
                    PKLog.trace("loadedMetadata info: \(event)")
                    self.sendAnalyticsEvent(ofType: .load)
                })
            case let e where e.self == PlayerEvent.playing:
                self.messageBus.addObserver(self, events: [PlayerEvent.playing], block: { event in
                    PKLog.trace("play info: \(event)")
                    
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
            default: assertionFailure("all events must be handled")
            }
        }
    }
    
    /************************************************************/
    // MARK: - Internal
    /************************************************************/
    
    func reportConcurrencyEvent() {
        self.messageBus.post(OttEvent.OttEventConcurrency())
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
        
        self.timer = Timer.every(self.interval) { [unowned self] in
            PKLog.trace("timerHit")
            
            self.sendAnalyticsEvent(ofType: .hit);
            
            let progress = Float(self.player.currentTime) / Float(self.player.duration)
            PKLog.trace("Progress is \(progress)")
            
            if progress > 0.98 {
                self.sendAnalyticsEvent(ofType: .finish)
            }
        }
    }
    
    fileprivate func stopTimer() {
        if let t = self.timer {
            t.invalidate()
        }
    }
}





