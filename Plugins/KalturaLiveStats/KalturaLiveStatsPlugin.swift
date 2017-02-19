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
    
    private unowned var player: Player
    private unowned var messageBus: MessageBus
    private var config: AnalyticsConfig?
    
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
    
    /************************************************************/
    // MARK: - PKPlugin
    /************************************************************/
    
    public weak var mediaEntry: MediaEntry?
    
    public required init(player: Player, pluginConfig: Any?, messageBus: MessageBus) {
        self.player = player
        self.messageBus = messageBus
        if let aConfig = pluginConfig as? AnalyticsConfig {
            self.config = aConfig
        }
        self.registerToAllEvents()
    }
    
    public func onLoad(mediaConfig: MediaConfig) {
        PKLog.trace("plugin \(type(of:self)) onLoad with media config: \(mediaConfig)")
        self.mediaEntry = mediaConfig.mediaEntry
    }
    
    public func onUpdateMedia(mediaConfig: MediaConfig) {
        PKLog.trace("plugin \(type(of:self)) onUpdateMedia with media config: \(mediaConfig)")
        self.mediaEntry = mediaConfig.mediaEntry
    }
    
    public func destroy() {
        eventIdx = 0
        if let t = self.timer {
            t.invalidate()
        }
    }
    
    /************************************************************/
    // MARK: - Private
    /************************************************************/
    
    private func registerToAllEvents() {
        
        PKLog.trace("registerToAllEvents")
        
        self.messageBus.addObserver(self, events: [PlayerEvent.play], block: { (event) in
            PKLog.trace("play info: \(event)")
            self.lastReportedStartTime = self.player.currentTime.toInt32()
            self.startLiveEvents()
        })
                
        self.messageBus.addObserver(self, events: [PlayerEvent.pause], block: { (event) in
            PKLog.trace("pause info: \(event)")
            self.stopLiveEvents()
        })
        
        self.messageBus.addObserver(self, events: [PlayerEvent.playbackParamsUpdated], block: { event in
            PKLog.trace("playbackParamsUpdated info: \(event)")
            if type(of: event) == PlayerEvent.playbackParamsUpdated {
                self.lastReportedBitrate = Int32(event.currentBitrate!)
            }
        })
        
        self.messageBus.addObserver(self, events: [PlayerEvent.stateChanged]) { event in
            PKLog.trace("playbackParamsUpdated info: \(event)")
            
            if type(of: event) == PlayerEvent.stateChanged {
                switch event.newState {
                case .ready:
                    self.startTimer()
                    if self.isBuffering {
                        self.isBuffering = false
                        self.sendLiveEvent(theBufferTime: self.calculateBuffer(isBuffering: false))
                    }
                case .buffering:
                    self.isBuffering = true
                    self.bufferStartTime = Date().timeIntervalSince1970.toInt32()
                default: break
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
        
        if let intr = self.config?.params["timerInterval"] as? Int {
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
        
        guard let mediaEntry = self.mediaEntry else { return }
        
        var sessionId = ""
        var baseUrl = "https://stats.kaltura.com/api_v3/index.php"
        var parterId = ""
        
        if let sId = self.config?.params["sessionId"] as? String {
            sessionId = sId
        }
        
        if let url = self.config?.params["baseUrl"] as? String {
            baseUrl = url
        }
        
        if let pId = self.config?.params["partnerId"] as? Int {
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
                                                                           entryId: mediaEntry.id,
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
