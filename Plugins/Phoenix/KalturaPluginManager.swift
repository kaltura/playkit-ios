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
    
    private var player: Player?
    private var messageBus: MessageBus?
    private var config: AnalyticsConfig?
    
    private var isFirstPlay = true
    private var intervalOn = false
    
    private var timer: Timer?
    private var interval = 30 //Should be provided in plugin config
    
    public func load(player: Player, pluginConfig: Any?, messageBus: MessageBus) {
        self.messageBus = messageBus
        
        if let aConfig = pluginConfig as? AnalyticsConfig {
            self.config = aConfig
            self.player = player
        }
        
        registerToAllEvents()
    }
    
    public func destroy() {
        self.delegate?.pluginManagerDidSendAnalyticsEvent(action: .stop)
        stopTimer()
        self.delegate = nil
    }
    
    func registerToAllEvents() {
        PKLog.trace("Register to all events")
        guard let messageBus = self.messageBus else {
            PKLog.error("messageBus is nil !")
            return
        }

        messageBus.addObserver(self, events: [PlayerEvents.ended.self], block: { (info) in
            PKLog.trace("ended info: \(info)")
            self.stopTimer()
            self.delegate?.pluginManagerDidSendAnalyticsEvent(action: .finish)
        })
        
        messageBus.addObserver(self, events: [PlayerEvents.error.self], block: { (info) in
            PKLog.trace("error info: \(info)")
            self.delegate?.pluginManagerDidSendAnalyticsEvent(action: .error)
        })
        
        messageBus.addObserver(self, events: [PlayerEvents.pause.self], block: { (info) in
            PKLog.trace("pause info: \(info)")
            self.delegate?.pluginManagerDidSendAnalyticsEvent(action: .pause)
        })
        
        messageBus.addObserver(self, events: [PlayerEvents.loadedMetadata.self], block: { (info) in
            PKLog.trace("loadedMetadata info: \(info)")
            self.delegate?.pluginManagerDidSendAnalyticsEvent(action: .load)
        })
        
        messageBus.addObserver(self, events: [PlayerEvents.playing.self], block: { (info) in
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
        
        if let player = self.player {
            var progress = Float(player.currentTime) / Float(player.duration)
            PKLog.trace("Progress is \(progress)")
            
            if progress > 0.98 {
                self.delegate?.pluginManagerDidSendAnalyticsEvent(action: .finish)
            }
        }
    }
    
    private func stopTimer() {
        if let t = self.timer {
            t.invalidate()
        }
    }
    
    public func reportConcurrencyEvent() {
        self.messageBus?.post(OttEvent.OttEventConcurrency())
    }
}
