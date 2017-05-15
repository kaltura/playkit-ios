//
//  YouboraAdnalyzerManager.swift
//  Pods
//
//  Created by Gal Orlanczyk on 20/04/2017.
//
//

import YouboraLib

class YouboraAdnalyzerManager: YBAdnalyzerGeneric {
    
    weak var adInfo: PKAdInfo?
    var adPlayhead: TimeInterval?
    var lastReportedResource: String?
    
    fileprivate weak var messageBus: MessageBus?
    
    override init!(pluginInstance plugin: YBPluginGeneric!) {
        super.init(pluginInstance: plugin)
        self.adnalyzerVersion = YBYouboraLibVersion + "-\(YouboraPlugin.kaltura)-" + PlayKitManager.clientTag // TODO: put plugin version when we will seperate
    }
    
    // we must override this init in order to override the `pluginInstance` init
    private override init() {
        super.init()
    }
}

/************************************************************/
// MARK: - Youbora AdnalyzerGeneric
/************************************************************/

extension YouboraAdnalyzerManager {
    
    override func startMonitoring(withPlayer player: NSObject!) {
        guard let messageBus = player as? MessageBus else {
            assertionFailure("our events handler object must be of type: `MessageBus`")
            return
        }
        super.startMonitoring(withPlayer: nil) // no need to pass our object it is not player type
        self.reset()
        self.messageBus = messageBus
        self.registerAdEvents(onMessageBus: messageBus)
    }
    
    override func stopMonitoring() {
        if let messageBus = self.messageBus {
            self.unregisterAdEvents(fromMessageBus: messageBus)
        }
        super.stopMonitoring()
    }
}

/************************************************************/
// MARK: - Youbora Info Methods
/************************************************************/

extension YouboraAdnalyzerManager {
    
    override func getAdPlayhead() -> NSNumber! {
        if let adPlayhead = self.adPlayhead, adPlayhead > 0 {
            return NSNumber(value: adPlayhead)
        } else {
            return super.getAdPlayhead()
        }
    }
    
    override func getAdPosition() -> String! {
        if let adInfo = self.adInfo {
            switch adInfo.positionType {
            case .preRoll: return "pre"
            case .midRoll: return "mid"
            case .postRoll: return "post"
            }
        } else {
            return super.getAdPosition()
        }
    }
    
    override func getAdTitle() -> String! {
        return adInfo?.title ?? super.getAdTitle()
    }
    
    override func getAdDuration() -> NSNumber! {
        if let adInfo = self.adInfo {
            return NSNumber(value: adInfo.duration)
        } else {
            return super.getAdDuration()
        }
    }
    
    override func getAdResource() -> String! {
        return lastReportedResource ?? super.getAdResource()
    }
    
    override func getAdPlayerVersion() -> String! {
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
                        self?.plugin.playHandler()
                    }
                    self?.playAdHandler()
                }
            case let e where e.self == AdEvent.adStarted:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    self?.joinAdHandler()
                }
            case let e where e.self == AdEvent.adComplete:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    self?.endedAdHandler()
                    self?.adInfo = nil
                }
            case let e where e.self == AdEvent.adResumed:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    self?.resumeAdHandler()
                    // if we were coming from background and ad was resumed
                    // has no effect when already playing ad and resumed because ad was already started.
                    self?.plugin?.playHandler()
                    self?.playAdHandler()
                    self?.joinAdHandler()
                }
            case let e where e.self == AdEvent.adPaused:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    self?.pauseAdHandler()
                }
            case let e where e.self == AdEvent.adDidProgressToTime:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    // update ad playhead with new data
                    self?.adPlayhead = event.adMediaTime?.doubleValue
                }
            case let e where e.self == AdEvent.adSkipped:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    self?.skipAdHandler()
                }
            case let e where e.self == AdEvent.adStartedBuffering:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    self?.bufferingAdHandler()
                }
            case let e where e.self == AdEvent.adPlaybackReady:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    self?.bufferedAdHandler()
                }
            case let e where e.self == AdEvent.adsRequested:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    self?.lastReportedResource = event.adTagUrl
                }
            // when ad request the content to resume (finished or error) 
            // make sure to send /adStop event and clear the info.
            case let e where e.self == AdEvent.adDidRequestContentResume:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    self?.endedAdHandler()
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
