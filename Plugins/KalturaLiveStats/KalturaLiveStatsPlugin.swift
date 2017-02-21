//
//  KalturaLiveStatsPlugin.swift
//  Pods
//
//  Created by Oded Klein on 01/12/2016.
//
//

public class KalturaLiveStatsPlugin: BaseAnalyticsPlugin {

    enum KLiveStatsEventType : Int {
        case LIVE = 1
        case DVR = 2
    }
    
    public override class var pluginName: String {
        return "KalturaLiveStats"
    }
    
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
    
    public override func destroy() {
        super.destroy()
        eventIdx = 0
        if let t = self.timer {
            t.invalidate()
        }
    }
    
    /************************************************************/
    // MARK: - AnalyticsPluginProtocol
    /************************************************************/
    
    override var playerEventsToRegister: [PlayerEvent.Type] {
        return [
            PlayerEvent.play,
            PlayerEvent.playbackParamsUpdated,
            PlayerEvent.pause,
            PlayerEvent.stateChanged
        ]
    }
    
    override func registerEvents() {
        PKLog.debug("register player events")
        
        self.playerEventsToRegister.forEach { event in
            PKLog.debug("Register event: \(event.self)")
            
            switch event {
            case let e where e.self == PlayerEvent.play:
                self.messageBus.addObserver(self, events: [e.self]){ [unowned self] event in
                    PKLog.debug("play event: \(event)")
                    self.lastReportedStartTime = self.player.currentTime.toInt32()
                    self.startLiveEvents()
                }
            case let e where e.self == PlayerEvent.pause:
                self.messageBus.addObserver(self, events: [e.self]) { [unowned self] event in
                    PKLog.debug("pause event: \(event)")
                    self.stopLiveEvents()
                }
            case let e where e.self == PlayerEvent.playbackParamsUpdated:
                self.messageBus.addObserver(self, events: [e.self]) { [unowned self] event in
                    PKLog.debug("playbackParamsUpdated event: \(event)")
                    if type(of: event) == PlayerEvent.playbackParamsUpdated {
                        self.lastReportedBitrate = Int32(event.currentBitrate!)
                    }
                }
            case let e where e.self == PlayerEvent.stateChanged:
                self.messageBus.addObserver(self, events: [e.self]) { [unowned self] event in
                    PKLog.debug("playbackParamsUpdated event: \(event)")
                    
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
            default: assertionFailure("all events must be handled")
            }
        }
    }
    
    /************************************************************/
    // MARK: - Private
    /************************************************************/
    
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
        PKLog.debug("sendLiveEvent - Buffer Time: \(bufferTime)")
        
        guard let mediaEntry = self.player.mediaEntry else { return }
        
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
                
                PKLog.debug("Response: \(response)")
                
            }
            USRExecutor.shared.send(request: builder.build())
        }
    }

}
