//
//  KalturaStatsPlugin.swift
//  Pods
//
//  Created by Oded Klein on 01/12/2016.
//
//

public class KalturaStatsPlugin: PKPlugin {

    enum KStatsEventType : Int {
        case WIDGET_LOADED = 1
        case MEDIA_LOADED = 2
        case PLAY = 3
        case PLAY_REACHED_25 = 4
        case PLAY_REACHED_50 = 5
        case PLAY_REACHED_75 = 6
        case PLAY_REACHED_100 = 7
        case OPEN_EDIT = 8
        case OPEN_VIRAL = 9
        case OPEN_DOWNLOAD = 10
        case OPEN_REPORT = 11
        case BUFFER_START = 12
        case BUFFER_END = 13
        case OPEN_FULL_SCREEN = 14
        case CLOSE_FULL_SCREEN = 15
        case REPLAY = 16
        case SEEK = 17
        case OPEN_UPLOAD = 18
        case SAVE_PUBLISH = 19
        case CLOSE_EDITOR = 20
        case PRE_BUMPER_PLAYED = 21
        case POST_BUMPER_PLAYED = 22
        case BUMPER_CLICKED = 23
        case PREROLL_STARTED = 24
        case MIDROLL_STARTED = 25
        case POSTROLL_STARTED = 26
        case OVERLAY_STARTED = 27
        case PREROLL_CLICKED = 28
        case MIDROLL_CLICKED = 29
        case POSTROLL_CLICKED = 30
        case OVERLAY_CLICKED = 31
        case PREROLL_25 = 32
        case PREROLL_50 = 33
        case PREROLL_75 = 34
        case MIDROLL_25 = 35
        case MIDROLL_50 = 36
        case MIDROLL_75 = 37
        case POSTROLL_25 = 38
        case POSTROLL_50 = 39
        case POSTROLL_75 = 40
        case ERROR = 99
    }
    
    private var player: Player!
    private var messageBus: MessageBus?
    private var config: AnalyticsConfig!
    private var mediaEntry: MediaEntry!
    
    public static var pluginName: String = "KalturaStatsPlugin"
    
    private var isFirstPlay = true
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
    private var interval = 30
    
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
        if let t = self.timer {
            t.invalidate()
        }
    }
    
    private func registerToAllEvents() {
        
        PKLog.trace("registerToAllEvents")
        
        self.messageBus?.addObserver(self, events: [PlayerEvents.canPlay.self], block: { (info) in
            PKLog.trace("canPlay info: \(info)")
            self.sendMediaLoaded()
        })
        
        self.messageBus?.addObserver(self, events: [PlayerEvents.play.self, PlayerEvents.playing.self], block: { (info) in
            PKLog.trace("play info: \(info)")
            if self.isFirstPlay {
                self.sendAnalyticsEvent(action: .PLAY)
                self.isFirstPlay = false
            }
        })
                
        self.messageBus?.addObserver(self, events: [PlayerEvents.pause.self], block: { (info) in
            PKLog.trace("pause info: \(info)")
        })
        
        self.messageBus?.addObserver(self, events: [PlayerEvents.seeking.self], block: { (info) in
            PKLog.trace("seeking info: \(info)")
        })
        
        self.messageBus?.addObserver(self, events: [PlayerEvents.seeked.self], block: { (info) in
            PKLog.trace("seeked info: \(info)")
            
            self.hasSeeked = true
            self.seekPercent = Float(self.player.currentTime) / Float(self.player.duration)
            self.sendAnalyticsEvent(action: .SEEK);
        })
        
        self.messageBus?.addObserver(self, events: [PlayerEvents.ended.self], block: { (info) in
            PKLog.trace("ended info: \(info)")
        })
        
        self.messageBus?.addObserver(self, events: [PlayerEvents.error.self], block: { (info) in
            PKLog.trace("error info: \(info)")
            self.sendAnalyticsEvent(action: .ERROR)
        })
        
        self.player.addObserver(self, events: [PlayerEvents.stateChanged.self]) { (data: Any) in
            
            if let stateChanged = data as? PlayerEvents.stateChanged {
                
                switch stateChanged.newSate {
                case .idle:
                    self.sendWidgetLoaded()
                    break
                case .loading:
                    self.sendWidgetLoaded()
                    if self.isBuffering {
                        self.isBuffering = false
                        self.sendAnalyticsEvent(action: .BUFFER_END)
                    }
                    break
                case .ready:
                    if self.isBuffering {
                        self.isBuffering = false
                        self.sendAnalyticsEvent(action: .BUFFER_END)
                    }
                    if !self.intervalOn {
                        self.intervalOn = true
                        self.createTimer()
                    }
                    self.sendMediaLoaded()
                    
                    break
                case .buffering:
                    self.sendWidgetLoaded()
                    self.isBuffering = true
                    self.sendAnalyticsEvent(action: .BUFFER_START)
                    break
                case .error:
                    
                    break
                }
            }
        }

    }
    
    private func sendWidgetLoaded() {
        if !self.isWidgetLoaded {
            sendAnalyticsEvent(action: .WIDGET_LOADED)
            self.isWidgetLoaded = true
        }
    }
    
    private func sendMediaLoaded(){
        if !self.isMediaLoaded {
            sendAnalyticsEvent(action: .MEDIA_LOADED)
            self.isMediaLoaded = true
        }
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
        
        if let intr = self.config.params["timerInterval"] as? Int {
            self.interval = intr
        }

        if let t = self.timer {
            t.invalidate()
        }
        
        self.timer = Timer.scheduledTimer(timeInterval: TimeInterval(self.interval), target: self, selector: #selector(KalturaStatsPlugin.timerHit), userInfo: nil, repeats: true)
        
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
                self.timer = Timer.scheduledTimer(timeInterval: TimeInterval(self.interval), target: self, selector: #selector(KalturaStatsPlugin.timerHit), userInfo: nil, repeats: true)
                self.timer!.fire()
            }
        }
    }
    
    private func pauseTimer() {
        if let t = self.timer {
            t.invalidate()
        }
    }
    
    private func sendAnalyticsEvent(action: KStatsEventType) {
        
        PKLog.trace("Action: \(action)")
        
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
        
        let builder: KalturaRequestBuilder = OVPStatsService.get(baseURL: baseUrl,
                                                                 partnerId: parterId,
                                                                 eventType: action.rawValue,
                                                                 clientVer: PlayKitManager.clientTag,
                                                                 duration: Float(self.player.duration),
                                                                 sessionId: sessionId,
                                                                 position: Float(self.player.currentTime),
                                                                 uiConfId: confId,
                                                                 entryId: self.mediaEntry.id,
                                                                 widgetId: "_\(parterId)",
                                                                 isSeek: hasSeeked)!
        
        builder.set { (response: Response) in
            
            PKLog.trace("Response code: \(response.statusCode)")
            
        }
        
        USRExecutor.shared.send(request: builder.build())
    }

}
