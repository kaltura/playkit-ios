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

class YouboraAdnalyzerManager: YBPlayerAdapter<AnyObject> {
    
    var adInfo: PKAdInfo?
    var adPlayhead: TimeInterval?
    var lastReportedResource: String?
    
    fileprivate weak var messageBus: MessageBus?
    
    // we must override this init in order to override the `pluginInstance` init
    private override init() {
        super.init()
    }
    
    override init(player: AnyObject) {
        super.init(player: player)
        guard let pkPlayer = player as? Player else {
            assertionFailure("player have to be of type: `Player`")
            return
        }
        self.player = pkPlayer
    }
}

/************************************************************/
// MARK: - Youbora AdnalyzerGeneric
/************************************************************/

extension YouboraAdnalyzerManager {
    
    override func registerListeners() {
        super.registerListeners()
        guard let messageBus = player as? MessageBus else {
            assertionFailure("our events handler object must be of type: `MessageBus`")
            return
        }
        self.reset()
        self.messageBus = messageBus
        self.registerAdEvents(onMessageBus: messageBus)
    }
    
    override func unregisterListeners() {
        if let messageBus = self.messageBus {
            self.unregisterAdEvents(fromMessageBus: messageBus)
        }
        super.unregisterListeners()
    }
}

/************************************************************/
// MARK: - Youbora Info Methods
/************************************************************/

extension YouboraAdnalyzerManager {
    
    override func getPlayhead() -> NSNumber? {
        if let adPlayhead = self.adPlayhead, adPlayhead > 0 {
            return NSNumber(value: adPlayhead)
        } else {
            return super.getPlayhead()
        }
    }
    
    override func getPosition() -> YBAdPosition {
        if let adInfo = self.adInfo {
            switch adInfo.positionType {
            case .preRoll: return YBAdPosition.pre
            case .midRoll: return YBAdPosition.mid
            case .postRoll: return YBAdPosition.post
            }
        } else {
            return super.getPosition()
        }
    }
    
    override func getTitle() -> String? {
        return adInfo?.title ?? super.getTitle()
    }
    
    override func getDuration() -> NSNumber? {
        if let adInfo = self.adInfo {
            return NSNumber(value: adInfo.duration)
        } else {
            return super.getDuration()
        }
    }
    
    override func getResource() -> String? {
        return lastReportedResource ?? super.getResource()
    }
    
    override func getPlayerVersion() -> String? {
        return PlayKitManager.clientTag
    }
}

/************************************************************/
// MARK: - Events Handling
/************************************************************/

extension YouboraAdnalyzerManager {
    
    private var adEventsToRegister: [AdEvent.Type] {
        return [
            AdEvent.adLoaded,
            AdEvent.adStarted,
            AdEvent.adComplete,
            AdEvent.adResumed,
            AdEvent.adPaused,
            AdEvent.adDidProgressToTime,
            AdEvent.adSkipped,
            AdEvent.adStartedBuffering,
            AdEvent.adPlaybackReady,
            AdEvent.adsRequested,
            AdEvent.adDidRequestContentResume
        ]
    }
    
    fileprivate func registerAdEvents(onMessageBus messageBus: MessageBus) {
        PKLog.debug("register ad events")
        
        self.adEventsToRegister.forEach { event in
            PKLog.debug("\(String(describing: type(of: self))) will register event: \(event.self)")
            
            switch event {
            case let e where e.self == AdEvent.adLoaded:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    // update ad info with the new loaded event
                    self?.adInfo = event.adInfo
                    // if ad is preroll make sure to call /start event before /adStart
                    if let positionType = event.adInfo?.positionType, positionType == .preRoll {
                        self?.plugin?.adapter?.fireStart()
                    }
                    self?.fireStart()
                }
            case let e where e.self == AdEvent.adStarted:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    self?.fireJoin()
                }
            case let e where e.self == AdEvent.adComplete:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    self?.fireStop()
                    self?.adInfo = nil
                }
            case let e where e.self == AdEvent.adResumed:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    self?.fireResume()
                    // if we were coming from background and ad was resumed
                    // has no effect when already playing ad and resumed because ad was already started.
                    self?.plugin?.adapter?.fireStart()
                    self?.fireStart()
                    self?.fireJoin()
                }
            case let e where e.self == AdEvent.adPaused:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    self?.firePause()
                }
            case let e where e.self == AdEvent.adDidProgressToTime:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    // update ad playhead with new data
                    self?.adPlayhead = event.adMediaTime?.doubleValue
                }
            case let e where e.self == AdEvent.adSkipped:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    self?.fireStop(["skipped":"true"])
                }
            case let e where e.self == AdEvent.adStartedBuffering:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    self?.fireBufferBegin()
                }
            case let e where e.self == AdEvent.adPlaybackReady:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    self?.fireBufferEnd()
                }
            case let e where e.self == AdEvent.adsRequested:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    self?.lastReportedResource = event.adTagUrl
                }
            // when ad request the content to resume (finished or error) 
            // make sure to send /adStop event and clear the info.
            case let e where e.self == AdEvent.adDidRequestContentResume:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    self?.fireStop()
                    self?.adInfo = nil
                }
            default: assertionFailure("all events must be handled")
            }
        }
    }
    
    func unregisterAdEvents(fromMessageBus messageBus: MessageBus) {
        messageBus.removeObserver(self, events: adEventsToRegister)
    }
}

/************************************************************/
// MARK: - Internal
/************************************************************/

extension YouboraAdnalyzerManager {
    
    /// resets the plugin's state.
    func reset() {
        self.adInfo = nil
        self.adPlayhead = -1
        self.lastReportedResource = nil
    }
}
