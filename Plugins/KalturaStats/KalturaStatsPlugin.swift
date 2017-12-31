// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import KalturaNetKit
import PlayKitUtils
import SwiftyJSON

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

public class KalturaStatsPlugin: BasePlugin, AnalyticsPluginProtocol {
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
    private var interval: TimeInterval = 10
    
    var config: KalturaStatsPluginConfig!
    /// indicates whether we played for the first time or not.
    public var isFirstPlay: Bool = true
    
    /************************************************************/
    // MARK: - PKPlugin
    /************************************************************/
    
    public override class var pluginName: String {
        return "KalturaStatsPlugin"
    }
    
    public required init(player: Player, pluginConfig: Any?, messageBus: MessageBus) throws {
        try super.init(player: player, pluginConfig: pluginConfig, messageBus: messageBus)
        
        var _config: KalturaStatsPluginConfig?
        if let json = pluginConfig as? JSON {
            _config = KalturaStatsPluginConfig.parse(json: json)
        } else {
            _config = pluginConfig as? KalturaStatsPluginConfig
        }
        
        guard let config = _config else {
            PKLog.error("missing plugin config or wrong plugin class type")
            throw PKPluginError.missingPluginConfig(pluginName: KalturaStatsPlugin.pluginName).asNSError
        }
        self.config = config
        self.registerEvents()
    }
    
    public override func onUpdateMedia(mediaConfig: MediaConfig) {
        super.onUpdateMedia(mediaConfig: mediaConfig)
        self.resetPlayerFlags()
        self.timer?.invalidate()
    }
    
    public override func onUpdateConfig(pluginConfig: Any) {
        super.onUpdateConfig(pluginConfig: pluginConfig)
        
        guard let config = pluginConfig as? KalturaStatsPluginConfig else {
            PKLog.error("plugin configis wrong")
            return
        }
        
        PKLog.debug("new config::\(String(describing: config))")
        self.config = config
    }
    
    public override func destroy() {
        self.messageBus?.removeObserver(self, events: playerEventsToRegister)
        if let t = self.timer {
            t.invalidate()
        }
        super.destroy()
    }
    
    /************************************************************/
    // MARK: - AnalyticsPluginProtocol
    /************************************************************/
    
    public var playerEventsToRegister: [PlayerEvent.Type] {
        return [
            PlayerEvent.error,
            PlayerEvent.canPlay,
            PlayerEvent.playing,
            PlayerEvent.seeked,
            PlayerEvent.stateChanged
        ]
    }
    
    public func registerEvents() {
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
                        strongSelf.sendAnalyticsEvent(action: .play)
                        strongSelf.isFirstPlay = false
                    }
                })
            case let e where e.self == PlayerEvent.error:
                self.messageBus?.addObserver(self, events: [e.self], block: { [weak self] (event) in
                    guard let strongSelf = self else { return }
                    PKLog.debug("error event: \(event)")
                    strongSelf.sendAnalyticsEvent(action: .error)
                })
            case let e where e.self == PlayerEvent.stateChanged:
                self.messageBus?.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    PKLog.debug("state changed event: \(event)")
                    if let stateChanged = event as? PlayerEvent.StateChanged {
                        switch stateChanged.newState {
                        case .idle:
                            strongSelf.sendWidgetLoaded()
                        case .ended:
                            PKLog.info("media ended")
                        case .ready:
                            if strongSelf.isBuffering {
                                strongSelf.isBuffering = false
                                strongSelf.sendAnalyticsEvent(action: .bufferEnd)
                            }
                            if !strongSelf.intervalOn {
                                strongSelf.intervalOn = true
                                strongSelf.createTimer()
                            }
                            strongSelf.sendMediaLoaded()
                        case .buffering:
                            strongSelf.sendWidgetLoaded()
                            strongSelf.isBuffering = true
                            strongSelf.sendAnalyticsEvent(action: .error)
                        case .error: break
                        case .unknown: break
                        }
                    }
                }
            default: assertionFailure("all events must be handled")
            }
        }
    }

    public func unregisterEvents() {
        self.messageBus?.removeObserver(self, events: playerEventsToRegister)
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
    
    private func resetPlayerFlags() {
        self.isWidgetLoaded = false
        self.isMediaLoaded = false
        self.isBuffering = false
        self.playReached25 = false
        self.playReached50 = false
        self.playReached75 = false
        self.playReached100 = false
        self.intervalOn = false
        self.hasSeeked = false
        self.isFirstPlay = true
    }
    
    private func createTimer() {
        if let t = self.timer {
            t.invalidate()
        }
        
        self.timer = PKTimer.every(self.interval) { _ in 
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
        PKLog.debug("Action: \(action)")
        
        // send event to messageBus
        let event = KalturaStatsEvent.Report(message: "send event with action type: \(action.rawValue)")
        self.messageBus?.post(event)
        
        guard let builder: KalturaRequestBuilder = OVPStatsService.get(config: self.config,
                                                                       eventType: action.rawValue,
                                                                       clientVer: PlayKitManager.clientTag,
                                                                       duration: Float(player.duration),
                                                                       sessionId: player.sessionId,
                                                                       position: player.currentTime.toInt32(),
                                                                       widgetId: "_\(self.config.partnerId)", isSeek: hasSeeked) else { return }
        
        builder.set { (response: Response) in
            PKLog.debug("Response: \(response)")
        }
        
        USRExecutor.shared.send(request: builder.build())
    }
}
