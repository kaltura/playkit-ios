// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import YouboraLib

class PKYouboraPlayerAdapter: YBPlayerAdapter<AnyObject> {

    private let KALTURA_IOS = "Kaltura-iOS"
    
    var lastReportedResource: String?
    /// The last reported playback info.
    var playbackInfo: PKPlaybackInfo?
    
    fileprivate weak var messageBus: MessageBus?
    fileprivate var config: YouboraConfig?
    
    /// Indicates whether we played for the first time or not.
    fileprivate var isFirstPlay: Bool = true
    
    /// Indicates if we have to delay the endedHandler() (for example when we have post-roll).
    fileprivate var shouldDelayEndedHandler = false
    
    private var lastReportedDuration: Double?
    
    // We must override this init in order to add our init (happens because of interopatability of youbora objc framework with swift).
    private override init() {
        super.init()
    }
    
    init(player: Player, messageBus: MessageBus, config: YouboraConfig?) {
        super.init(player: player)
        
        self.config = config
        // We cann't set the messageBus before the super init because Objective C calls init() which resets our object.
        // Therfore we have to call registerListeners again after messageBus is set.
        // Once/If they change to Swift, this can be changed.
        self.messageBus = messageBus
        registerListeners()
    }
}

/************************************************************/
// MARK: - Youbora PluginGeneric
/************************************************************/

extension PKYouboraPlayerAdapter {
    
    override func registerListeners() {
        super.registerListeners()
        reset()
        registerEvents()
    }
    
    override func unregisterListeners() {
        unregisterEvents()
        super.unregisterListeners()
    }
}

/************************************************************/
// MARK: - Youbora Info Methods
/************************************************************/

extension PKYouboraPlayerAdapter {
    
    override func getDuration() -> NSNumber? {
        guard let player = self.player else {
            return nil
        }
        return NSNumber(value: player.duration)
    }
    
    override func getResource() -> String? {
        return lastReportedResource ?? super.getResource()
    }
    
    override func getTitle() -> String? {
        return player?.mediaEntry?.id ?? super.getTitle()
    }
    
    override func getPlayhead() -> NSNumber? {
        let currentTime = player?.currentTime
        return currentTime != nil ? NSNumber(value: currentTime!) : super.getPlayhead()
    }
    
    override func getPlayerVersion() -> String? {
        return YouboraPlugin.kaltura + "-" + PlayKitManager.clientTag
    }
    
    override func getIsLive() -> NSValue? {
        guard let player = self.player as? PlayerController else {
            return super.getIsLive()
        }
        
        return NSNumber(value:player.isLive())
    }
    
    override func getBitrate() -> NSNumber? {
        if let playbackInfo = playbackInfo, playbackInfo.bitrate > 0 {
            return NSNumber(value: playbackInfo.bitrate)
        }
        return super.getBitrate()
    }
    
    override func getThroughput() -> NSNumber? {
        if let playbackInfo = playbackInfo, playbackInfo.observedBitrate > 0 {
            return NSNumber(value: playbackInfo.observedBitrate)
        }
        return super.getThroughput()
    }
    
    override func getRendition() -> String? {
        if let pi = playbackInfo, pi.indicatedBitrate > 0 && pi.bitrate > 0 && pi.bitrate != pi.indicatedBitrate {
            return YBYouboraUtils.buildRenditionString(withWidth: 0, height: 0, andBitrate: pi.indicatedBitrate)
        }
        return super.getRendition()
    }
    
    override func fireJoin() {
        guard let duration = lastReportedDuration else {
            super.fireJoin()
            return
        }
        super.fireJoin(["duration": String(describing: duration), "mediaDuration": String(describing: duration)])
    }
    
    override func getVersion() -> String {
        return YouboraLibVersion + "-" + PlayKitManager.versionString + "-" + (getPlayerVersion() ?? "")
    }
    
    override func getPlayerName() -> String? {
        return KALTURA_IOS
    }
    
    override func getHouseholdId() -> String {
        return config?.houseHoldId ?? ""
    }
}

/************************************************************/
// MARK: - Events Handling
/************************************************************/

extension PKYouboraPlayerAdapter {
    
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
            PlayerEvent.durationChanged,
            AdEvent.adCuePointsUpdate,
            AdEvent.allAdsCompleted
        ]
    }
    
    fileprivate func registerEvents() {
        PKLog.debug("Register events")
        
        guard let messageBus = self.messageBus else { return }
        
        self.eventsToRegister.forEach { event in
            PKLog.debug("Register event: \(event.self)")
            
            switch event {
            case let e where e.self == PlayerEvent.play:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    // Play handler to start when asset starts loading.
                    // This point is the closest point to prepare call.
                    strongSelf.fireStart()
                    strongSelf.postEventLog(withMessage: "\(event.namespace)")
                }
            case let e where e.self == PlayerEvent.stopped:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    // We must call `fireStop()` when stopped so youbora will know player stopped playing content.
                    strongSelf.plugin?.adsAdapter?.fireStop()
                    strongSelf.fireStop()
                    strongSelf.postEventLog(withMessage: "\(event.namespace)")
                }
            case let e where e.self == PlayerEvent.pause:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    strongSelf.firePause()
                    strongSelf.postEventLog(withMessage: "\(event.namespace)")
                }
            case let e where e.self == PlayerEvent.playing:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    strongSelf.fireJoin()
                    strongSelf.fireBufferEnd()
                    if strongSelf.isFirstPlay {
                        strongSelf.isFirstPlay = false
                        //strongSelf.fireJoin()
                        //strongSelf.fireBufferEnd()
                    } else {
                        strongSelf.fireResume()
                    }
                    strongSelf.postEventLog(withMessage: "\(String(describing: event.namespace))")
                }
            case let e where e.self == PlayerEvent.seeking:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    strongSelf.fireSeekBegin()
                    strongSelf.postEventLog(withMessage: "\(event.namespace)")
                }
            case let e where e.self == PlayerEvent.seeked:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    strongSelf.fireSeekEnd()
                    strongSelf.postEventLog(withMessage: "\(event.namespace)")
                }
            case let e where e.self == PlayerEvent.ended:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    if !strongSelf.shouldDelayEndedHandler {
                        strongSelf.fireStop()
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
                        strongSelf.fireBufferBegin()
                        strongSelf.postEventLog(withMessage: "\(event.namespace)")
                    }
                }
            case let e where e.self == PlayerEvent.sourceSelected:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    strongSelf.lastReportedResource = event.mediaSource?.playbackUrl?.absoluteString
                    strongSelf.postEventLog(withMessage: "\(event.namespace)")
                }
            case let e where e.self == PlayerEvent.error:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    if let error = event.error, error.code == PKErrorCode.playerItemFailed {
                        strongSelf.fireFatalError(withMessage: error.localizedDescription, code: "\(error.code)", andMetadata: error.description)
                    }
                }
            case let e where e.self == PlayerEvent.durationChanged:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    strongSelf.lastReportedDuration = event.duration?.doubleValue
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
                        self?.plugin?.adsAdapter?.fireStop()
                        self?.fireStop()
                    }
                }
            default: assertionFailure("All events must be handled")
            }
        }
    }
    
    fileprivate func unregisterEvents() {
        messageBus?.removeObserver(self, events: eventsToRegister)
    }
}

/************************************************************/
// MARK: - Internal
/************************************************************/

extension PKYouboraPlayerAdapter {
    
    func resetForBackground() {
        playbackInfo = nil
        isFirstPlay = true
    }
    
    func reset() {
        playbackInfo = nil
        lastReportedResource = nil
        isFirstPlay = true
        shouldDelayEndedHandler = false
    }
}

/************************************************************/
// MARK: - Private
/************************************************************/

extension PKYouboraPlayerAdapter {
    
    fileprivate func postEventLog(withMessage message: String) {
        let eventLog = YouboraEvent.Report(message: message)
        messageBus?.post(eventLog)
    }
}
