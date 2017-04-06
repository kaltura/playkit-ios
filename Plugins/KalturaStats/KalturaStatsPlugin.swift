//
//  KalturaStatsPlugin.swift
//  Pods
//
//  Created by Oded Klein on 01/12/2016.
//
//

/// `KalturaStatsEvent` represents an event reporting from kaltura stats plugin.
@objc public class KalturaStatsEvent: PKEvent {
    
    static let messageKey = "message"
    
    class Report: KalturaStatsEvent {
        convenience init(message: String) {
            self.init([KalturaStatsEvent.messageKey: message])
        }
    }
    
    @objc public static let report: KalturaStatsEvent.Type = Report.self
}

extension PKEvent {
    /// bufferTime Value, PKEvent Data Accessor
    @objc public var kalturaStatsMessage: String? {
        return self.data?[KalturaStatsEvent.messageKey] as? String
    }
}

public class KalturaStatsPlugin: BaseAnalyticsPlugin {
    
    // stats event types
    enum KalturaStatsEventType : Int {
        case widgetLoaded = 1
        case mediaLoaded = 2
        case play = 3
        case playReached25 = 4
        case playReached50 = 5
        case playReached75 = 6
        case playReached100 = 7
        case openEdit = 8
        case openViral = 9
        case openDownload = 10
        case openReport = 11
        case bufferStart = 12
        case bufferEnd = 13
        case openFullScreen = 14
        case closeFullScreen = 15
        case replay = 16
        case seek = 17
        case openUpload = 18
        case savePublish = 19
        case closeEditor = 20
        case preBumperPlayed = 21
        case postBumperPlayed = 22
        case bumperClicked = 23
        case prerollStarted = 24
        case midrollStarted = 25
        case postRollStarted = 26
        case overlayStarted = 27
        case prerollClicked = 28
        case midrollClicked = 29
        case postRollClicked = 30
        case overlayClicked = 31
        case preRoll25 = 32
        case preRoll50 = 33
        case preRoll75 = 34
        case midRoll25 = 35
        case midRoll50 = 36
        case midRoll75 = 37
        case postRoll25 = 38
        case postRoll50 = 39
        case postRoll75 = 40
        case error = 99
    }
    
    public override class var pluginName: String {
        return "KalturaStatsPlugin"
    }
    
    private var isWidgetLoaded = false
    private var isMediaLoaded = false
    private var isBuffering = false

    private var seekPercent: Float = 0.0
    
    private var playReached25 = false
    private var playReached50 = false
    private var playReached75 = false
    private var playReached100 = false
    private var intervalOn = false
    private var hasSeeked = false
    
    private var timer: Timer?
    private var interval: TimeInterval = 30
    
    /************************************************************/
    // MARK: - AnalyticsPluginProtocol
    /************************************************************/
    
    override var playerEventsToRegister: [PlayerEvent.Type] {
        return [
            PlayerEvent.error,
            PlayerEvent.canPlay,
            PlayerEvent.playing,
            PlayerEvent.seeked,
            PlayerEvent.stateChanged
        ]
    }
    
    override func registerEvents() {
        PKLog.debug("register player events")
        
        self.playerEventsToRegister.forEach { event in
            PKLog.debug("Register event: \(event.self)")
            
            switch event {
            case let e where e.self == PlayerEvent.canPlay:
                self.messageBus?.addObserver(self, events: [e.self], block: { [weak self] (event) in
                    guard let strongSelf = self else { return }
                    PKLog.debug("canPlay event: \(event)")
                    strongSelf.sendMediaLoaded()
                })
            case let e where e.self == PlayerEvent.seeked:
                self.messageBus?.addObserver(self, events: [e.self], block: { [weak self] (event) in
                    guard let strongSelf = self, let player = self?.player else { return }
                    PKLog.debug("seeked event: \(event)")
                    strongSelf.hasSeeked = true
                    strongSelf.seekPercent = Float(player.currentTime) / Float(player.duration)
                    strongSelf.sendAnalyticsEvent(action: .seek)
                })
            case let e where e.self == PlayerEvent.playing:
                self.messageBus?.addObserver(self, events: [e.self], block: { [weak self] (event) in
                    guard let strongSelf = self else { return }
                    PKLog.debug("play event: \(event)")
                    if strongSelf.isFirstPlay {
                        strongSelf.sendEvent(ofType: .play, withMessage: "Play event")
                        strongSelf.isFirstPlay = false
                    }
                })
            case let e where e.self == PlayerEvent.error:
                self.messageBus?.addObserver(self, events: [e.self], block: { [weak self] (event) in
                    guard let strongSelf = self else { return }
                    PKLog.debug("error event: \(event)")
                    strongSelf.sendEvent(ofType: .error, withMessage: "Error event")
                })
            case let e where e.self == PlayerEvent.stateChanged:
                self.messageBus?.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    PKLog.debug("state changed event: \(event)")
                    if let stateChanged = event as? PlayerEvent.StateChanged {
                        switch stateChanged.newState {
                        case .idle:
                            strongSelf.sendWidgetLoaded()
                        case .loading:
                            strongSelf.sendWidgetLoaded()
                            if strongSelf.isBuffering {
                                strongSelf.isBuffering = false
                                strongSelf.sendEvent(ofType: .bufferEnd, withMessage: "Buffer end event")
                            }
                        case .ready:
                            if strongSelf.isBuffering {
                                strongSelf.isBuffering = false
                                strongSelf.sendEvent(ofType: .bufferEnd, withMessage: "Buffer end event")
                            }
                            if !strongSelf.intervalOn {
                                strongSelf.intervalOn = true
                                strongSelf.createTimer()
                            }
                            strongSelf.sendMediaLoaded()
                        case .buffering:
                            strongSelf.sendWidgetLoaded()
                            strongSelf.isBuffering = true
                            strongSelf.sendEvent(ofType: .bufferStart, withMessage: "Buffer start event")
                        case .error: break
                        case .unknown: break
                        }
                    }
                }
            default: assertionFailure("all events must be handled")
            }
        }
    }
    
    /************************************************************/
    // MARK: - PKPlugin
    /************************************************************/
    
    public override func destroy() {
        super.destroy()
        if let t = self.timer {
            t.invalidate()
        }
    }
    
    /************************************************************/
    // MARK: - Private Implementation
    /************************************************************/
    
    private func sendWidgetLoaded() {
        if !self.isWidgetLoaded {
            sendAnalyticsEvent(action: .widgetLoaded)
            self.isWidgetLoaded = true
        }
    }
    
    private func sendMediaLoaded(){
        if !self.isMediaLoaded {
            sendAnalyticsEvent(action: .mediaLoaded)
            self.isMediaLoaded = true
        }
    }
    
    private func sendEvent(ofType type: KalturaStatsEventType, withMessage message: String) {
        // send event to messageBus
        let event = KalturaStatsEvent.Report(message: message)
        self.messageBus?.post(event)
        // send event to analytics entity
        self.sendAnalyticsEvent(action: type)
    }
    
    private func resetPlayerFlags() {
        isFirstPlay = true
        hasSeeked = false
        isBuffering = false
        isMediaLoaded = false
        isWidgetLoaded = false
        playReached25 = false
        playReached50 = false
        playReached75 = false
        playReached100 = false
    }
    
    private func createTimer() {
        
        if let intr = self.config?.params["timerInterval"] as? TimeInterval {
            self.interval = intr
        }

        if let t = self.timer {
            t.invalidate()
        }
        
        self.timer = Timer.every(self.interval) {
            guard let player = self.player else { return }
            let progress = Float(player.currentTime) / Float(player.duration)
            PKLog.debug("Progress is \(progress)")
            
            if progress >= 0.25 && !self.playReached25 && self.seekPercent <= 0.25 {
                self.playReached25 = true
                self.sendAnalyticsEvent(action: .playReached25)
            } else if progress >= 0.5 && !self.playReached50 && self.seekPercent < 0.5 {
                self.playReached50 = true
                self.sendAnalyticsEvent(action: .playReached50)
            } else if progress >= 0.75 && !self.playReached75 && self.seekPercent <= 0.75 {
                self.playReached75 = true
                self.sendAnalyticsEvent(action: .playReached75)
            } else if progress >= 0.98 && !self.playReached100 && self.seekPercent < 1 {
                self.playReached100 = true
                self.sendAnalyticsEvent(action: .playReached100)
            }
        }
    }
    
    private func pauseTimer() {
        if let t = self.timer {
            t.invalidate()
        }
    }
    
    private func sendAnalyticsEvent(action: KalturaStatsEventType) {
        guard let player = self.player else { return }
        
        guard let mediaEntry = player.mediaEntry else {
            PKLog.error("send analytics failed due to nil mediaEntry")
            return
        }
        
        PKLog.debug("Action: \(action)")
        
        let entryId: String
        let sessionId = player.sessionId.uuidString
        var baseUrl = "https://stats.kaltura.com/api_v3/index.php"
        var confId = 0
        var parterId = ""
        
        if let cId = self.config?.params["uiconfId"] as? Int {
            confId = cId
        }
        
        if let url = self.config?.params["baseUrl"] as? String {
            baseUrl = url
        }
        
        if let pId = self.config?.params["partnerId"] as? Int {
            parterId = String(pId)
        }
        
        if let eId = self.config?.params["entryId"] as? String {
            entryId = eId
        } else {
            entryId = mediaEntry.id
        }
        
        guard let builder: KalturaRequestBuilder = OVPStatsService.get(baseURL: baseUrl,
                                                                 partnerId: parterId,
                                                                 eventType: action.rawValue,
                                                                 clientVer: PlayKitManager.clientTag,
                                                                 duration: Float(player.duration),
                                                                 sessionId: sessionId,
                                                                 position: player.currentTime.toInt32(),
                                                                 uiConfId: confId,
                                                                 entryId: entryId,
                                                                 widgetId: "_\(parterId)",
                                                                 isSeek: hasSeeked) else { return }
        
        builder.set { (response: Response) in
            PKLog.debug("Response: \(response)")
        }
        
        USRExecutor.shared.send(request: builder.build())
    }

}
