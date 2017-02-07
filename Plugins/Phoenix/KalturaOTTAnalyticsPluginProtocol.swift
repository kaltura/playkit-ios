//
//  KalturaOTTAnalyticsPluginProtocol
//  Pods
//
//  Created by Gal Orlanczyk on 31/01/2017.
//
//

import Foundation

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

protocol KalturaOTTAnalyticsPluginProtocol: PKPlugin {
    
    unowned var player: Player { get set }
    unowned var messageBus: MessageBus { get set }
    var config: AnalyticsConfig? { get set }
    var isFirstPlay: Bool { get set }
    var intervalOn: Bool { get set }
    var timer: Timer? { get set }
    var interval: TimeInterval { get set }
    
    func sendAnalyticsEvent(ofType type: PhoenixAnalyticsType)
    func buildRequest(ofType type: PhoenixAnalyticsType) -> Request?
    func send(request: Request)
}

extension KalturaOTTAnalyticsPluginProtocol {
    
    func sendAnalyticsEvent(ofType type: PhoenixAnalyticsType) {
        PKLog.trace("Event type: \(type)")
        if let request = self.buildRequest(ofType: type) {
            self.send(request: request)
        }
    }
    
    func registerToAllEvents() {
        PKLog.trace("Register to all events")
        
        self.messageBus.addObserver(self, events: [PlayerEvent.ended], block: { event in
            PKLog.trace("ended info: \(event)")
            self.stopTimer()
            self.sendAnalyticsEvent(ofType: .finish)
        })
        
        self.messageBus.addObserver(self, events: [PlayerEvent.error], block: { event in
            PKLog.trace("error info: \(event)")
            self.sendAnalyticsEvent(ofType: .error)
        })
        
        self.messageBus.addObserver(self, events: [PlayerEvent.pause], block: { event in
            PKLog.trace("pause info: \(event)")
            self.sendAnalyticsEvent(ofType: .pause)
        })
        
        self.messageBus.addObserver(self, events: [PlayerEvent.loadedMetadata], block: { event in
            PKLog.trace("loadedMetadata info: \(event)")
            self.sendAnalyticsEvent(ofType: .load)
        })
        
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
    }
    
    func createTimer() {
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
    
    func stopTimer() {
        if let t = self.timer {
            t.invalidate()
        }
    }
    
    func reportConcurrencyEvent() {
        self.messageBus.post(OttEvent.OttEventConcurrency())
    }
}

