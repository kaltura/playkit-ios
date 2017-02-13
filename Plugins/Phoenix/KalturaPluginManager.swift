//
//  KalturaPluginManager.swift
//  Pods
//
//  Created by Oded Klein on 13/12/2016.
//
//

import UIKit

enum PhoenixAnalyticsType: String {
    case hit
    case play
    case stop
    case pause
    case first_play
    case swoosh
    case load
    case finish
    case bitrate_change
    case error
}

protocol KalturaPluginManagerDelegate {
    func pluginManagerDidSendAnalyticsEvent(action: PhoenixAnalyticsType)
}

final class KalturaPluginManager {

    public var delegate: KalturaPluginManagerDelegate?
    
    private unowned var player: Player
    private unowned var messageBus: MessageBus
    private var config: AnalyticsConfig?
    
    private var isFirstPlay = true
    private var intervalOn = false
    
    private var timer: Timer?
    private var interval = 30 //Should be provided in plugin config
    
    init(player: Player, pluginConfig: Any?, messageBus: MessageBus) {
        self.player = player
        self.messageBus = messageBus
        self.load(pluginConfig: pluginConfig)
    }
    
    func load(pluginConfig: Any?) {
        if let aConfig = pluginConfig as? AnalyticsConfig {
            self.config = aConfig
        }
        self.registerToAllEvents()
        AppStateSubject.sharedInstance.add(observer: self)
    }
    
    public func destroy() {
        self.delegate?.pluginManagerDidSendAnalyticsEvent(action: .stop)
        stopTimer()
        self.delegate = nil
    }
    
    func registerToAllEvents() {
        PKLog.trace("Register to all events")

        self.messageBus.addObserver(self, events: [PlayerEvent.ended], block: { (info) in
            PKLog.trace("ended info: \(info)")
            self.stopTimer()
            self.delegate?.pluginManagerDidSendAnalyticsEvent(action: .finish)
        })
        
        self.messageBus.addObserver(self, events: [PlayerEvent.error], block: { (info) in
            PKLog.trace("error info: \(info)")
            self.delegate?.pluginManagerDidSendAnalyticsEvent(action: .error)
        })
        
        self.messageBus.addObserver(self, events: [PlayerEvent.pause], block: { (info) in
            PKLog.trace("pause info: \(info)")
            self.delegate?.pluginManagerDidSendAnalyticsEvent(action: .pause)
        })
        
        self.messageBus.addObserver(self, events: [PlayerEvent.loadedMetadata], block: { (info) in
            PKLog.trace("loadedMetadata info: \(info)")
            self.delegate?.pluginManagerDidSendAnalyticsEvent(action: .load)
        })
        
        self.messageBus.addObserver(self, events: [PlayerEvent.playing], block: { (info) in
            PKLog.trace("play info: \(info)")
            
            if !self.intervalOn {
                self.createTimer()
                self.intervalOn = true
            }
            
            if self.isFirstPlay {
                self.isFirstPlay = false
                self.delegate?.pluginManagerDidSendAnalyticsEvent(action: .first_play);
            } else {
                self.delegate?.pluginManagerDidSendAnalyticsEvent(action: .play);
            }
        })
    }
    
    public func reportConcurrencyEvent() {
        self.messageBus.post(OttEvent.Concurrency())
    }
    
    /************************************************************/
    // MARK: - Private Implementation
    /************************************************************/
    
    private func createTimer() {
        
        if let conf = self.config, let intr = conf.params["timerInterval"] as? Int {
            self.interval = intr
        }
        
        if let t = self.timer {
            t.invalidate()
        }
        
        self.timer = Timer.scheduledTimer(timeInterval: TimeInterval(self.interval), target: self, selector: #selector(KalturaPluginManager.timerHit), userInfo: nil, repeats: true)
        
    }
    
    @objc private func timerHit() {
        
        PKLog.trace("timerHit")
        
        self.delegate?.pluginManagerDidSendAnalyticsEvent(action: .hit);
        
        var progress = Float(player.currentTime) / Float(player.duration)
        PKLog.trace("Progress is \(progress)")
        
        if progress > 0.98 {
            self.delegate?.pluginManagerDidSendAnalyticsEvent(action: .finish)
        }
    }
    
    private func stopTimer() {
        if let t = self.timer {
            t.invalidate()
        }
    }
}

/************************************************************/
// MARK: - App State Handling
/************************************************************/

extension KalturaPluginManager: AppStateObservable {
    
    var observations: Set<NotificationObservation> {
        return [
            NotificationObservation(name: .UIApplicationWillTerminate) { [unowned self] in
                guard let delegate = self.delegate else { return }
                PKLog.trace("plugin: \(delegate) will terminate event received, sending analytics stop event")
                self.destroy()
                AppStateSubject.sharedInstance.remove(observer: self)
            }
        ]
    }
}
