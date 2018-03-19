// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

#if os(iOS)
    import YouboraLib
#elseif os(tvOS)
    import YouboraLibTvOS
#endif

class YouboraManager: YBPluginGeneric {

    fileprivate weak var pkPlayer: Player?
    var lastReportedResource: String?
    /// The last reported playback info.
    var playbackInfo: PKPlaybackInfo?
    
    fileprivate weak var messageBus: MessageBus?
    
    /// Indicates whether we played for the first time or not.
    fileprivate var isFirstPlay: Bool = true
    
    /// Indicates if we have to delay the endedHandler() (for example when we have post-roll).
    fileprivate var shouldDelayEndedHandler = false
    
    init(options: NSObject!, player: Player) {
        super.init(options: options)
        self.pluginName = "\(YouboraPlugin.kaltura)-iOS"
        self.pluginVersion = YBYouboraLibVersion + "-\(YouboraPlugin.kaltura)-" + PlayKitManager.clientTag // TODO: put plugin version when we will seperate
        self.pkPlayer = player
    }
    
    // We must override this init in order to add our init (happens because of interopatability of youbora objc framework with swift). 
    private override init() {
        super.init()
    }
}

/************************************************************/
// MARK: - Youbora PluginGeneric
/************************************************************/

extension YouboraManager {
    
    override func startMonitoring(withPlayer player: NSObject!) {
        guard let messageBus = player as? MessageBus else {
            assertionFailure("our events handler object must be of type: `MessageBus`")
            return
        }
        super.startMonitoring(withPlayer: nil) // no need to pass our object it is not player type
        self.reset()
        self.messageBus = messageBus
        self.registerEvents(onMessageBus: messageBus)
    }
    
    override func stopMonitoring() {
        if let messageBus = self.messageBus {
            self.unregisterEvents(fromMessageBus: messageBus)
        }
        super.stopMonitoring()
    }
}

/************************************************************/
// MARK: - Youbora Info Methods
/************************************************************/

extension YouboraManager {
    
    override func getMediaDuration() -> NSNumber! {
        let duration = self.pkPlayer?.duration
        return duration != nil ? NSNumber(value: duration!) : super.getMediaDuration()
    }
    
    override func getResource() -> String! {
        return self.lastReportedResource ?? super.getResource()
    }
    
    override func getTitle() -> String! {
        return self.pkPlayer?.mediaEntry?.id ?? super.getTitle()
    }
    
    override func getPlayhead() -> NSNumber! {
        let currentTime = self.pkPlayer?.currentTime
        return currentTime != nil ? NSNumber(value: currentTime!) : super.getPlayhead()
    }
    
    override func getPlayerVersion() -> String! {
        return "\(PlayKitManager.clientTag)"
    }
    
    override func getIsLive() -> NSValue! {
        if let mediaType = self.pkPlayer?.mediaEntry?.mediaType {
            if mediaType == .live {
                return NSNumber(value: true)
            }
            return NSNumber(value: false)
        }
        return super.getIsLive()
    }
    
    override func getBitrate() -> NSNumber! {
        if let playbackInfo = self.playbackInfo, playbackInfo.bitrate > 0 {
            return NSNumber(value: playbackInfo.bitrate)
        }
        return super.getBitrate()
    }
    
    override func getThroughput() -> NSNumber! {
        if let playbackInfo = self.playbackInfo, playbackInfo.observedBitrate > 0 {
            return NSNumber(value: playbackInfo.observedBitrate)
        }
        return super.getThroughput()
    }
    
    override func getRendition() -> String! {
        if let pi = self.playbackInfo, pi.indicatedBitrate > 0 && pi.bitrate > 0 && pi.bitrate != pi.indicatedBitrate {
            return YBUtils.buildRenditionString(withBitrate: pi.indicatedBitrate)
        }
        return super.getRendition()
    }
}

/************************************************************/
// MARK: - Events Handling
/************************************************************/

extension YouboraManager {
    
    private var eventsToRegister: [PKEvent.Type] {
        return [
            PlayerEvent.play,
            PlayerEvent.stopped,
            PlayerEvent.pause,
            PlayerEvent.playing,
            PlayerEvent.seeking,
            PlayerEvent.seeked,
            PlayerEvent.ended,
            PlayerEvent.playbackInfo,
            PlayerEvent.stateChanged,
            PlayerEvent.sourceSelected,
            PlayerEvent.error,
            AdEvent.adCuePointsUpdate,
            AdEvent.allAdsCompleted
        ]
    }
    
    fileprivate func registerEvents(onMessageBus messageBus: MessageBus) {
        PKLog.debug("register events")
        
        self.eventsToRegister.forEach { event in
            PKLog.debug("Register event: \(event.self)")
            
            switch event {
            case let e where e.self == PlayerEvent.play:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    // play handler to start when asset starts loading.
                    // this point is the closest point to prepare call.
                    strongSelf.playHandler()
                    strongSelf.postEventLog(withMessage: "\(event.namespace)")
                }
            case let e where e.self == PlayerEvent.stopped:
                self.messageBus?.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    // we must call `endedHandler()` when stopped so youbora will know player stopped playing content.
                    strongSelf.adnalyzer?.endedAdHandler()
                    strongSelf.endedHandler()
                    strongSelf.postEventLog(withMessage: "\(event.namespace)")
                }
            case let e where e.self == PlayerEvent.pause:
                self.messageBus?.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    strongSelf.pauseHandler()
                    strongSelf.postEventLog(withMessage: "\(event.namespace)")
                }
            case let e where e.self == PlayerEvent.playing:
                self.messageBus?.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    if strongSelf.isFirstPlay {
                        strongSelf.isFirstPlay = false
                        strongSelf.joinHandler()
                        strongSelf.bufferedHandler()
                    } else {
                        strongSelf.resumeHandler()
                    }
                    strongSelf.postEventLog(withMessage: "\(String(describing: event.namespace))")
                }
            case let e where e.self == PlayerEvent.seeking:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    strongSelf.seekingHandler()
                    strongSelf.postEventLog(withMessage: "\(event.namespace)")
                }
            case let e where e.self == PlayerEvent.seeked:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    strongSelf.seekedHandler()
                    strongSelf.postEventLog(withMessage: "\(event.namespace)")
                }
            case let e where e.self == PlayerEvent.ended:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    if !strongSelf.shouldDelayEndedHandler {
                        strongSelf.endedHandler()
                    }
                    strongSelf.postEventLog(withMessage: "\(event.namespace)")
                }
            case let e where e.self == PlayerEvent.playbackInfo:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    strongSelf.playbackInfo = event.playbackInfo
                    strongSelf.postEventLog(withMessage: "\(event.namespace)")
                }
            case let e where e.self == PlayerEvent.stateChanged:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    if event.newState == .buffering {
                        strongSelf.bufferingHandler()
                        strongSelf.postEventLog(withMessage: "\(event.namespace)")
                    }
                }
            case let e where e.self == PlayerEvent.sourceSelected:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    self?.lastReportedResource = event.mediaSource?.playbackUrl?.absoluteString
                    strongSelf.postEventLog(withMessage: "\(event.namespace)")
                }
            case let e where e.self == PlayerEvent.error:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    if let error = event.error, error.code == PKErrorCode.playerItemFailed {
                        strongSelf.errorHandler(withCode: "\(error.code)", message: error.localizedDescription, andErrorMetadata: error.description)
                    }
                }
            case let e where e.self == AdEvent.adCuePointsUpdate:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    if let hasPostRoll = event.adCuePoints?.hasPostRoll, hasPostRoll == true {
                        self?.shouldDelayEndedHandler = true
                    }
                }
            case let e where e.self == AdEvent.allAdsCompleted:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    if let shouldDelayEndedHandler = self?.shouldDelayEndedHandler, shouldDelayEndedHandler == true {
                        self?.shouldDelayEndedHandler = false
                        self?.adnalyzer?.endedAdHandler()
                        self?.endedHandler()
                    }
                }
            default: assertionFailure("all events must be handled")
            }
        }
    }
    
    fileprivate func unregisterEvents(fromMessageBus messageBus: MessageBus) {
        messageBus.removeObserver(self, events: eventsToRegister)
    }
}

/************************************************************/
// MARK: - Internal
/************************************************************/

extension YouboraManager {
    
    func resetForBackground() {
        self.playbackInfo = nil
        self.isFirstPlay = true
    }
    
    func reset() {
        self.playbackInfo = nil
        self.lastReportedResource = nil
        self.isFirstPlay = true
        self.shouldDelayEndedHandler = false
    }
}

/************************************************************/
// MARK: - Private
/************************************************************/

extension YouboraManager {
    
    fileprivate func postEventLog(withMessage message: String) {
        let eventLog = YouboraEvent.Report(message: message)
        self.messageBus?.post(eventLog)
    }
}
