// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license,
// unless a different license for a particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================
import KalturaNetKit

/// `KalturaStatsEvent` represents an event reporting from kaltura stats plugin.
@objc public class KalturaLiveStatsEvent: PKEvent {
    
    static let bufferTimeKey = "bufferTime"
    
    class Report: KalturaLiveStatsEvent {
        convenience init(bufferTime: Int32) {
            self.init([Report.bufferTimeKey: NSNumber(value: bufferTime)])
        }
    }
    
    @objc public static let report: KalturaLiveStatsEvent.Type = Report.self
}

extension PKEvent {
    /// bufferTime Value, PKEvent Data Accessor
    @objc public var kalturaLiveStatsBufferTime: NSNumber? {
        return self.data?[KalturaLiveStatsEvent.bufferTimeKey] as? NSNumber
    }
}

public class KalturaLiveStatsPlugin: BasePlugin, AnalyticsPluginProtocol {

    enum KLiveStatsEventType : Int {
        case live = 1
        case dvr = 2
    }
    
    public override class var pluginName: String {
        return "KalturaLiveStats"
    }
    
    /// the allowed distance from the live playhead to be considered as live.
    /// values greater than these are considered dvr playback.
    private let distanceFromLiveThreshold: TimeInterval = 15.0
    
    private var isLive = false
    private var eventIdx = 1
    private var currentBitrate = -1
    private var bufferTime: Int32 = 0
    private var bufferStartTime: Int32 = 0
    private var lastReportedBitrate: Int32 = -1
    private var lastReportedStartTime: Int32 = 0
    private var isBuffering = false
    private var timer: Timer?
    private var config: KalturaLiveStatsPluginConfig!
    /// indicates whether we played for the first time or not.
    var isFirstPlay: Bool = true
    
    private let interval = 10.0
    
    /************************************************************/
    // MARK: - PKPlugin
    /************************************************************/
    
    public required init(player: Player, pluginConfig: Any?, messageBus: MessageBus) throws {
        try super.init(player: player, pluginConfig: pluginConfig, messageBus: messageBus)
        guard let config = pluginConfig as? KalturaLiveStatsPluginConfig else {
            PKLog.error("missing plugin config or wrong plugin class type")
            throw PKPluginError.missingPluginConfig(pluginName: KalturaStatsPlugin.pluginName)
        }
        self.config = config
        self.registerEvents()
    }
    
    public override func onUpdateMedia(mediaConfig: MediaConfig) {
        self.isLive = false
        self.eventIdx = 1
        self.currentBitrate = -1
        self.bufferTime = 0
        self.bufferStartTime = 0
        self.lastReportedBitrate = -1
        self.lastReportedStartTime = 0
        self.isBuffering = false
        self.isFirstPlay = true
        self.timer?.invalidate()
    }
    
    public override func onUpdateConfig(pluginConfig: Any) {
        super.onUpdateConfig(pluginConfig: pluginConfig)
        
        guard let config = pluginConfig as? KalturaLiveStatsPluginConfig else {
            PKLog.error("plugin config is wrong type")
            return
        }
        
        PKLog.debug("new config::\(String(describing: config))")
        self.config = config
    }
    
    public override func destroy() {
        super.destroy()
        if let t = self.timer {
            t.invalidate()
        }
    }
    
    /************************************************************/
    // MARK: - AnalyticsPluginProtocol
    /************************************************************/
    
    var playerEventsToRegister: [PlayerEvent.Type] {
        return [
            PlayerEvent.play,
            PlayerEvent.playing,
            PlayerEvent.playbackInfo,
            PlayerEvent.pause,
            PlayerEvent.error,
            PlayerEvent.stateChanged
        ]
    }
    
    func registerEvents() {
        PKLog.debug("register player events")
        
        self.playerEventsToRegister.forEach { event in
            PKLog.debug("Register event: \(event.self)")
            
            switch event {
            case let e where e.self == PlayerEvent.play:
                self.messageBus?.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self, let player = self?.player else { return }
                    strongSelf.lastReportedStartTime = player.currentTime.toInt32()
                    strongSelf.startLiveEvents()
                }
            case let e where e.self == PlayerEvent.playing:
                self.messageBus?.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    strongSelf.startLiveEvents()
                }
            case let e where e.self == PlayerEvent.pause:
                self.messageBus?.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    strongSelf.stopLiveEvents()
                }
            case let e where e.self == PlayerEvent.error:
                self.messageBus?.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    strongSelf.stopLiveEvents()
                }
            case let e where e.self == PlayerEvent.playbackInfo:
                self.messageBus?.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    if type(of: event) == PlayerEvent.playbackInfo && event.playbackInfo != nil {
                        strongSelf.lastReportedBitrate = Int32(event.playbackInfo!.bitrate)
                    }
                }
            case let e where e.self == PlayerEvent.stateChanged:
                self.messageBus?.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    
                    if type(of: event) == PlayerEvent.stateChanged {
                        switch event.newState {
                        case .ready:
                            strongSelf.createTimer()
                            if strongSelf.isBuffering {
                                strongSelf.isBuffering = false
                                strongSelf.sendLiveEvent(withBufferTime: strongSelf.calculateBuffer(isBuffering: false))
                            }
                        case .buffering:
                            strongSelf.isBuffering = true
                            strongSelf.bufferStartTime = Date().timeIntervalSince1970.toInt32()
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
            self.createTimer()
            isLive = true
            if isFirstPlay {
                sendLiveEvent(withBufferTime: bufferTime);
                isFirstPlay = false
            }
        }
    }
    
    private func stopLiveEvents(){
        self.isLive = false
        self.timer?.invalidate()
        self.timer = nil
    }
    
    private func createTimer() {
        if let t = self.timer {
            t.invalidate()
        }
        self.timer = Timer.every(self.interval) { [weak self] in
            self?.sendLiveEvent(withBufferTime: self?.bufferTime ?? 0)
            self?.eventIdx += 1
            PKLog.debug("current time: \(String(describing: self?.player?.currentTime)), duration: \(String(describing: self?.player?.duration))")
        }
    }
    
    private func calculateBuffer(isBuffering: Bool) -> Int32 {
        
        let currTime = Date().timeIntervalSince1970.toInt32()
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
    
    private func sendLiveEvent(withBufferTime bufferTime: Int32) {
        guard let player = self.player else { return }
        
        PKLog.debug("sendLiveEvent - Buffer Time: \(bufferTime)")
        // post event to message bus
        let event = KalturaLiveStatsEvent.Report(bufferTime: bufferTime)
        self.messageBus?.post(event)
        
        let sessionId = player.sessionId
        
        let eventType: KLiveStatsEventType = (player.duration - player.currentTime) > self.distanceFromLiveThreshold ? .dvr : .live
        
        if let builder: RequestBuilder = LiveStatsService.sendLiveStatsEvent(
            baseURL: self.config.baseUrl,
            partnerId: "\(self.config.partnerId)", eventType: eventType.rawValue,
            eventIndex: self.eventIdx,
            bufferTime: bufferTime,
            bitrate: self.lastReportedBitrate,
            sessionId: sessionId,
            startTime: self.lastReportedStartTime,
            entryId: self.config.entryId,
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
