//
//  KalturaPluginManager.swift
//  Pods
//
//  Created by Oded Klein on 13/12/2016.
//
//

import UIKit

internal enum PhoenixAnalyticsType: String {
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
    func sendAnalyticsEvent(action: PhoenixAnalyticsType)
}

internal class KalturaPluginManager {

    public var delegate: KalturaPluginManagerDelegate?
    
    private var player: Player!
    private var messageBus: MessageBus?
    private var config: AnalyticsConfig!
    
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
        self.delegate?.sendAnalyticsEvent(action: .stop)
        stopTimer()
    }
    
    func registerToAllEvents() {
        
        
        self.messageBus?.addObserver(self, events: [PlayerEvents.ended.self], block: { (info) in
            PKLog.trace("ended info: \(info)")
            self.stopTimer()
            self.delegate?.sendAnalyticsEvent(action: .finish)
        })
        
        self.messageBus?.addObserver(self, events: [PlayerEvents.error.self], block: { (info) in
            PKLog.trace("error info: \(info)")
            self.delegate?.sendAnalyticsEvent(action: .error)
        })
        
        self.messageBus?.addObserver(self, events: [PlayerEvents.pause.self], block: { (info) in
            PKLog.trace("pause info: \(info)")
            self.delegate?.sendAnalyticsEvent(action: .pause)
        })
        
        self.messageBus?.addObserver(self, events: [PlayerEvents.loadedMetadata.self], block: { (info) in
            PKLog.trace("loadedMetadata info: \(info)")
            self.delegate?.sendAnalyticsEvent(action: .load)
        })
        
        self.messageBus?.addObserver(self, events: [PlayerEvents.loadedMetadata.self], block: { (info) in
            PKLog.trace("play info: \(info)")
            
            if !self.intervalOn {
                self.createTimer()
                self.intervalOn = true
            }
            
            if self.isFirstPlay {
                self.isFirstPlay = false
                self.delegate?.sendAnalyticsEvent(action: .first_play);
            } else {
                self.delegate?.sendAnalyticsEvent(action: .play);
            }
            
            
        })
        
    }
    
    private func createTimer() {
        
        if let intr = self.config.params["timerInterval"] as? Int {
            self.interval = intr
        }
        
        if let t = self.timer {
            t.invalidate()
        }
        
        self.timer = Timer.scheduledTimer(timeInterval: TimeInterval(self.interval), target: self, selector: #selector(KalturaPluginManager.timerHit), userInfo: nil, repeats: true)
        
    }
    
    @objc private func timerHit() {
        
        PKLog.trace("timerHit")
        
        self.delegate?.sendAnalyticsEvent(action: .hit);
        
        var progress = Float(self.player.currentTime) / Float(self.player.duration)
        PKLog.trace("Progress is \(progress)")
        
        if progress > 0.98 {
            self.delegate?.sendAnalyticsEvent(action: .finish)
        }
    }
    
    private func stopTimer() {
        if let t = self.timer {
            t.invalidate()
        }
    }
    
}
