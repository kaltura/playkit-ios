//
//  YouboraAdnalyzerManager.swift
//  Pods
//
//  Created by Gal Orlanczyk on 20/04/2017.
//
//

import Foundation
import YouboraLib

class YouboraAdnalyzerManager: YBAdnalyzerGeneric {
    
    weak var adInfo: PKAdInfo?
    var adPlayhead: TimeInterval = -1
    var lastReportedResource: String?
    
    fileprivate weak var messageBus: MessageBus?
    
    override init!(pluginInstance plugin: YBPluginGeneric!) {
        super.init(pluginInstance: plugin)
        self.adnalyzerVersion = PlayKitManager.versionString // TODO: put plugin version when we will seperate
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
        if self.adPlayhead > 0 {
            return NSNumber(value: self.adPlayhead)
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
    
    var adEventsToRegister: [AdEvent.Type] {
        return [
            AdEvent.adLoaded,
            AdEvent.adStarted,
            AdEvent.adComplete,
            AdEvent.adResumed,
            AdEvent.adPaused,
            AdEvent.adDidProgressToTime,
            AdEvent.adSkipped,
            AdEvent.adStartedBuffering,
            AdEvent.adPlaybackReady
            // TODO: add ad tag event
        ]
    }
    
    func registerAdEvents(onMessageBus messageBus: MessageBus) {
        PKLog.debug("register player events")
        
        self.adEventsToRegister.forEach { event in
            PKLog.debug("Register event: \(event.self)")
            
            switch event {
            case let e where e.self == AdEvent.adLoaded:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    // update ad info with the new loaded event
                    self?.adInfo = event.adInfo
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
                }
            case let e where e.self == AdEvent.adPaused:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    self?.pauseAdHandler()
                }
            case let e where e.self == AdEvent.adDidProgressToTime:
                messageBus.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let progress = event.adMediaTime?.doubleValue else { return }
                    // update ad playhead with new data
                    self?.adPlayhead = progress
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
                // TODO: add ad tag event
            default: assertionFailure("all events must be handled")
            }
        }
    }
    
    func unregisterAdEvents(fromMessageBus messageBus: MessageBus) {
        messageBus.removeObserver(self, events: adEventsToRegister)
    }
}

/************************************************************/
// MARK: - Private
/************************************************************/

extension YouboraAdnalyzerManager {
    
    /// resets the plugin's state.
    fileprivate func reset() {
        self.adInfo = nil
        self.adPlayhead = -1
        self.lastReportedResource = nil
    }
}
