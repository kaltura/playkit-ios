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
    private var lastReportedBitrate: Int32 = -1
    private var lastReportedStartTime: Int32 = 0
    
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
        
        self.messageBus?.addObserver(self, events: [PlayerEvent.play], block: { (info) in
            PKLog.trace("play info: \(info)")
            self.lastReportedStartTime = self.player.currentTime.toInt32()
            self.startLiveEvents()
        })
                
        self.messageBus?.addObserver(self, events: [PlayerEvent.pause], block: { (info) in
            PKLog.trace("pause info: \(info)")
            self.stopLiveEvents()
        })
        
        self.messageBus?.addObserver(self, events: [PlayerEvent.playbackParamsUpdated], block: { info in
            PKLog.trace("playbackParamsUpdated info: \(info)")
            
            if type(of: info) == PlayerEvent.playbackParamsUpdated {
                self.lastReportedBitrate = Int32(info.currentBitrate!)
            }
        })
        
        self.player.addObserver(self, events: [PlayerEvent.stateChanged]) { data in
            
            if type(of: data) == PlayerEvent.stateChanged {
                switch data.newState {
                case .ready:
                    self.startTimer()
                    if self.isBuffering {
                        self.isBuffering = false
                        self.sendLiveEvent(theBufferTime: self.calculateBuffer(isBuffering: false))
                    }
                    break
                case .buffering:
                    self.isBuffering = true
                    self.bufferStartTime = Date().timeIntervalSince1970.toInt32()
                    break
                default:
                    
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
                sendLiveEvent(theBufferTime: bufferTime);
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
        self.sendLiveEvent(theBufferTime: bufferTime);
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
    
    private func sendLiveEvent(theBufferTime: Int32) {
        
        PKLog.trace("sendLiveEvent - Buffer Time: \(bufferTime)")
        
        var sessionId = ""
        var baseUrl = "https://stats.kaltura.com/api_v3/index.php"
        var parterId = ""
        
        if let sId = self.config.params["sessionId"] as? String {
            sessionId = sId
        }
        
        if let url = self.config.params["baseUrl"] as? String {
            baseUrl = url
        }
        
        if let pId = self.config.params["partnerId"] as? Int {
            parterId = String(pId)
        }
        
        if let builder: RequestBuilder = LiveStatsService.sendLiveStatsEvent(baseURL: baseUrl,
                                                                           partnerId: parterId,
                                                                           eventType: self.isLive ? 1 : 0,
                                                                           eventIndex: self.eventIdx,
                                                                           bufferTime: theBufferTime,
                                                                           bitrate: self.lastReportedBitrate,
                                                                           sessionId: sessionId,
                                                                           startTime: self.lastReportedStartTime,
                                                                           entryId: self.mediaEntry.id,
                                                                           isLive: isLive,
                                                                           clientVer: PlayKitManager.clientTag,
                                                                           deliveryType: "hls") {
            
            builder.set { (response: Response) in
                
                PKLog.trace("Response: \(response)")
                
            }
            
            USRExecutor.shared.send(request: builder.build())
            
        }
    }

}
