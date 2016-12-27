//
//  KalturaLiveStatsPlugin.swift
//  Pods
//
//  Created by Oded Klein on 01/12/2016.
//
//

public class KalturaLiveStatsPlugin: PKPlugin {

    enum KLiveStatsEventType : Int {
        case LIVE = 1
        case DVR = 2
    }
    
    private var player: Player!
    private var messageBus: MessageBus?
    private var config: AnalyticsConfig!
    private var mediaEntry: MediaEntry!
    
    public static var pluginName: String = "KalturaLiveStats"
    
    private var isFirstPlay = true
    private var isLive = false
    private var eventIdx = 0
    private var currentBitrate = -1
    private var bufferTime: Int32 = 0
    private var bufferStartTime: Int32 = 0
    private var isBuffering = false
    
    private var timer: Timer?
    private var interval = 10
    
    required public init() {
        
    }
    
    public func load(player: Player, mediaConfig: MediaEntry, pluginConfig: Any?, messageBus: MessageBus) {
        
        self.messageBus = messageBus
        self.mediaEntry = mediaConfig
        
        if let aConfig = pluginConfig as? AnalyticsConfig {
            self.config = aConfig
            self.player = player
        }
        
        registerToAllEvents()
        
    }
    
    public func destroy() {
        eventIdx = 0
        if let t = self.timer {
            t.invalidate()
        }
    }
    
    private func registerToAllEvents() {
        
        PKLog.trace("registerToAllEvents")
        
        self.messageBus?.addObserver(self, events: [PlayerEvents.play.self, PlayerEvents.playing.self], block: { (info) in
            PKLog.trace("play info: \(info)")
            self.startLiveEvents()
        })
                
        self.messageBus?.addObserver(self, events: [PlayerEvents.pause.self], block: { (info) in
            PKLog.trace("pause info: \(info)")
            self.stopLiveEvents()
        })
        
        self.player.addObserver(self, events: [PlayerEvents.stateChanged.self]) { (data: Any) in
            
            if let stateChanged = data as? PlayerEvents.stateChanged {
                
                switch stateChanged.newSate {
                case .ready:
                    self.startTimer()
                    if self.isBuffering {
                        self.isBuffering = false
                        self.sendLiveEvent(bufferTime: self.calculateBuffer(isBuffering: false))
                    }
                    break
                case .buffering:
                    self.isBuffering = true
                    self.bufferStartTime = Date().timeIntervalSince1970.toInt32()
                    break
                case .error:
                    
                    break
                }
            }
        }

    }
    
    private func startLiveEvents() {
        if !self.isLive {
            startTimer()
            isLive = true
            if isFirstPlay {
                sendLiveEvent(bufferTime: bufferTime);
                isFirstPlay = false
            }
        }
    }
    
    private func stopLiveEvents(){
        self.isLive = false
    }
    
    private func createTimer() {
        
        if let intr = self.config.params["timerInterval"] as? Int {
            self.interval = intr
        }

        if let t = self.timer {
            t.invalidate()
        }
        
        self.timer = Timer.scheduledTimer(timeInterval: TimeInterval(self.interval), target: self, selector: #selector(KalturaLiveStatsPlugin.timerHit), userInfo: nil, repeats: true)
        
    }
    
    @objc private func timerHit() {
        var progress = Float(self.player.currentTime) / Float(self.player.duration)
        PKLog.trace("Progress is \(progress)")
        
        if progress >= 0.25 && !playReached25 && seekPercent <= 0.25 {
            playReached25 = true
            sendAnalyticsEvent(action: .PLAY_REACHED_25);
        } else if progress >= 0.5 && !playReached50 && seekPercent < 0.5 {
            playReached50 = true
            sendAnalyticsEvent(action: .PLAY_REACHED_50);
        } else if progress >= 0.75 && !playReached75 && seekPercent <= 0.75 {
            playReached75 = true
            sendAnalyticsEvent(action: .PLAY_REACHED_75);
        } else if progress >= 0.98 && !playReached100 && seekPercent < 1 {
            playReached100 = true
            sendAnalyticsEvent(action: .PLAY_REACHED_100)
        }

    }
    
    private func startTimer() {
        if let t = self.timer {
            if t.isValid {
                t.fire()
            } else {
                self.timer = Timer.scheduledTimer(timeInterval: TimeInterval(self.interval), target: self, selector: #selector(KalturaLiveStatsPlugin.timerHit), userInfo: nil, repeats: true)
                self.timer!.fire()
            }
        }
    }
    
    private func pauseTimer() {
        if let t = self.timer {
            t.invalidate()
        }
    }
    
    private func calculateBuffer(isBuffering: Bool) -> Int32 {
        
        var currTime = Date().timeIntervalSince1970.toInt32()
        bufferTime = (currTime - bufferStartTime) / 1000;
        if bufferTime > 10 {
            bufferTime = 10;
        }
        if isBuffering {
            bufferStartTime = Date().timeIntervalSince1970.toInt32()
        } else {
            bufferStartTime = -1
        }
        return bufferTime
    }
    
    private func sendLiveEvent(bufferTime: Int32) {
        
        PKLog.trace("Buffer Time: \(bufferTime)")
        
        var sessionId = ""
        var baseUrl = ""
        var confId = 0
        var parterId = ""
        
        if let sId = self.config.params["sessionId"] as? String {
            sessionId = sId
        }
        
        if let cId = self.config.params["uiconfId"] as? Int {
            confId = cId
        }
        
        if let url = self.config.params["baseUrl"] as? String {
            baseUrl = url
        }
        
        if let pId = self.config.params["partnerId"] as? Int {
            parterId = String(pId)
        }
        
        /*
        let builder: KalturaRequestBuilder = OVPStatsService.get(baseURL: baseUrl,
                                                                 partnerId: parterId,
                                                                 eventType: action.rawValue,
                                                                 clientVer: PlayKitManager.clientTag,
                                                                 duration: Float(self.player.duration),
                                                                 sessionId: sessionId,
                                                                 position: self.player.currentTime.toInt32(),
                                                                 uiConfId: confId,
                                                                 entryId: self.mediaEntry.id,
                                                                 widgetId: "_\(parterId)",
                                                                 isSeek: hasSeeked)!
        
        builder.set { (response: Response) in
            
            PKLog.trace("Response: \(response)")
            
        }
        
        USRExecutor.shared.send(request: builder.build())
         */
    }

}
