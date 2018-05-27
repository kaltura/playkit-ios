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

class PKYouboraAdsAdapter: YBPlayerAdapter<AnyObject> {
    
    private let KALTURA_IOS = "Kaltura-iOS"
    
    var adInfo: PKAdInfo?
    var adPlayhead: TimeInterval?
    var lastReportedResource: String?
    
    fileprivate weak var messageBus: MessageBus?
    
    // We must override this init in order to add our init (happens because of interopatability of youbora objc framework with swift).
    private override init() {
        super.init()
    }
    
    init(player: Player, messageBus: MessageBus) {
        super.init(player: player)
        
        // We cann't set the messageBus before the super init because Objective C calls init() which resets our object.
        // Therfore we have to call registerListeners again after messageBus is set.
        // Once/If they change to Swift, this can be changed.
        self.messageBus = messageBus
        registerListeners()
    }
}

/************************************************************/
// MARK: - Youbora AdnalyzerGeneric
/************************************************************/

extension PKYouboraAdsAdapter {
    
    override func registerListeners() {
        super.registerListeners()
        reset()
        registerAdEvents()
    }
    
    override func unregisterListeners() {
        unregisterAdEvents()
        super.unregisterListeners()
    }
}

/************************************************************/
// MARK: - Youbora Info Methods
/************************************************************/

extension PKYouboraAdsAdapter {
    
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
        return YouboraPlugin.kaltura + "-" + PlayKitManager.clientTag
    }
    
    override func getVersion() -> String {
        return YouboraLibVersion + "-" + PlayKitManager.versionString + "-" + (getPlayerVersion() ?? "")
    }
    
    override func getPlayerName() -> String? {
        return KALTURA_IOS
    }
}

/************************************************************/
// MARK: - Events Handling
/************************************************************/

extension PKYouboraAdsAdapter {
    
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
            AdEvent.adClicked,
            AdEvent.adDidRequestContentResume
        ]
    }
    
    fileprivate func registerAdEvents() {
        PKLog.debug("Register ad events")
        
        guard let messageBus = self.messageBus else { return }
        
        adEventsToRegister.forEach { event in
            PKLog.debug("\(String(describing: type(of: self))) will register event: \(event.self)")
            
            switch event {
            case let e where e.self == AdEvent.adLoaded:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    // Update ad info with the new loaded event
                    strongSelf.adInfo = event.adInfo
                    // If ad is preroll make sure to call /start event before /adStart
                    if let positionType = event.adInfo?.positionType, positionType == .preRoll {
                        strongSelf.plugin?.adapter?.fireStart()
                    }
                    strongSelf.fireStart()
                }
            case let e where e.self == AdEvent.adStarted:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    strongSelf.fireJoin()
                }
            case let e where e.self == AdEvent.adComplete:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    strongSelf.fireStop()
                    strongSelf.adInfo = nil
                }
            case let e where e.self == AdEvent.adResumed:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    strongSelf.fireResume()
                    // If we were coming from background and ad was resumed
                    // Has no effect when already playing ad and resumed because ad was already started.
                    strongSelf.plugin?.adapter?.fireStart()
                    strongSelf.fireStart()
                    strongSelf.fireJoin()
                }
            case let e where e.self == AdEvent.adPaused:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    strongSelf.firePause()
                }
            case let e where e.self == AdEvent.adDidProgressToTime:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    // Update ad playhead with new data
                    strongSelf.adPlayhead = event.adMediaTime?.doubleValue
                }
            case let e where e.self == AdEvent.adSkipped:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    strongSelf.fireStop(["skipped":"true"])
                }
            case let e where e.self == AdEvent.adStartedBuffering:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    strongSelf.fireBufferBegin()
                }
            case let e where e.self == AdEvent.adPlaybackReady:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    strongSelf.fireBufferEnd()
                }
            case let e where e.self == AdEvent.adsRequested:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    strongSelf.lastReportedResource = event.adTagUrl
                }
            // When ad request the content to resume (finished or error)
            // Make sure to send /adStop event and clear the info.
            case let e where e.self == AdEvent.adDidRequestContentResume:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    strongSelf.fireStop()
                    strongSelf.adInfo = nil
                }
            case let e where e.self == AdEvent.adClicked:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    strongSelf.fireClick()
                }
            default: assertionFailure("All events must be handled")
            }
        }
    }
    
    func unregisterAdEvents() {
        messageBus?.removeObserver(self, events: adEventsToRegister)
    }
}

/************************************************************/
// MARK: - Internal
/************************************************************/

extension PKYouboraAdsAdapter {
    
    // Resets the plugin's state.
    func reset() {
        adInfo = nil
        adPlayhead = -1
        lastReportedResource = nil
    }
}
