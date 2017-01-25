//
//  PlayerEvent.swift
//  Pods
//
//  Created by Eliza Sapir on 14/11/2016.
//
//
import Foundation

// MARK: - Event Data Keys
let kDuration = "duration"
let kTracks = "tracks"
let kCurrentBitrate = "currentBitrate"
let kOldState = "oldState"
let kNewState = "newState"

/// An PlayerEvents is a class used to reflect player events.

public class PlayerEvents: PKEvent {
    
    // All events EXCLUDING error. Assuming error events are treated differently.
    public static let allEventTypes: [PlayerEvents.Type] = [
        canPlay.self, durationChange.self, ended.self, loadedMetadata.self,
        play.self, paused.self, playing.self, seeking.self, seeked.self, stateChanged.self
    ]
    
    // MARK: - Player Events Static Reference
    
    /// Sent when enough data is available that the media can be played, at least for a couple of frames.
    @objc public static let canPlayEvent = canPlay.self
    /// The metadata has loaded or changed, indicating a change in duration of the media. This is sent, for example, when the media has loaded enough that the duration is known.
    @objc public static let durationChangeEvent = durationChange.self
    /// Sent when playback completes.
    @objc public static let endedEvent = ended.self
    /// The media's metadata has finished loading; all attributes now contain as much useful information as they're going to.
    @objc public static let loadedMetadataEvent = loadedMetadata.self
    /// Sent when an error occurs.
    @objc public static let errorEvent = error.self
    /// Sent when playback of the media starts after having been paused; that is, when playback is resumed after a prior pause event.
    @objc public static let playEvent = play.self
    /// Sent when playback is paused.
    @objc public static let pausedEvent = paused.self
    /// Sent when the media begins to play (either for the first time, after having been paused, or after ending and then restarting).
    @objc public static let playingEvent = playing.self
    /// Sent when a seek operation begins.
    @objc public static let seekingEvent = seeking.self
    /// Sent when a seek operation completes.
    @objc public static let seekedEvent = seeked.self
    /// Sent when tracks available.
    @objc public static let tracksAvailableEvent = tracksAvailable.self
    /// Sent when Playback Params Updated.
    @objc public static let playbackParamsUpdatedEvent = playbackParamsUpdated.self
    /// Sent when player state is changed.
    @objc public static let stateChangedEvent = stateChanged.self
    
    // MARK: - Player Basic Events

    public class canPlay : PlayerEvents {}
    public class durationChange : PlayerEvents {
        public var duration: TimeInterval
        
        init(duration: TimeInterval) {
            self.duration = duration
        }
        
        override public func data() -> [String : AnyObject]? {
            return [kDuration: NSNumber(value: duration)]
        }
    }
    
    public class ended : PlayerEvents {}
    public class loadedMetadata : PlayerEvents {}
    public class error : PlayerEvents {}
    public class play : PlayerEvents {}
    public class paused : PlayerEvents {}
    public class playing : PlayerEvents {}
    public class seeking : PlayerEvents {}
    public class seeked : PlayerEvents {}
    
    // MARK: - Player Tracks Events
    
    public class tracksAvailable : PlayerEvents {
        public var tracks: PKTracks
        
        public init(tracks: PKTracks) {
            self.tracks = tracks
        }
        
        override public func data() -> [String : AnyObject]? {
            return [kTracks: tracks]
        }
    }
    
    public class playbackParamsUpdated : PlayerEvents {
        public var currentBitrate: Double
        
        init(currentBitrate: Double) {
            self.currentBitrate = currentBitrate
        }
        
        override public func data() -> [String : AnyObject]? {
            return [kCurrentBitrate: NSNumber(value: currentBitrate)]
        }
    }
    
    // MARK: - Player State Events

    public class stateChanged : PlayerEvents {
        public var newState: PlayerState
        public var oldState: PlayerState
        
        public init(newState: PlayerState, oldState: PlayerState) {
            self.newState = newState
            self.oldState = oldState
        }
        
        override public func data() -> [String : AnyObject]? {
            return [kNewState: newState as AnyObject, kOldState: oldState as AnyObject]
        }
    }
}

// MARK: - Ad Events

public class AdEvents: PKEvent {
    
    public static let allEventTypes: [AdEvents.Type] = [
        adBreakReady.self, adBreakEnded.self, adBreakStarted.self, adAllCompleted.self, adComplete.self, adClicked.self, adCuepointsChanged.self, adFirstQuartile.self, adLoaded.self, adLog.self, adMidpoint.self, adPaused.self, adResumed.self, adSkipped.self, adStarted.self, adStreamLoaded.self, adTapped.self, adThirdQuartile.self, adDidProgressToTime.self, adDidRequestPause.self, adDidRequestResume.self, adWebOpenerWillOpenExternalBrowser.self, adWebOpenerWillOpenInAppBrowser.self, adWebOpenerDidOpenInAppBrowser.self, adWebOpenerWillCloseInAppBrowser.self, adWebOpenerDidCloseInAppBrowser.self 
    ]
    
    public class adBreakReady : AdEvents {}
    public class adBreakEnded : AdEvents {}
    public class adBreakStarted : AdEvents {}
    public class adAllCompleted : AdEvents {}
    public class adComplete : AdEvents {}
    public class adClicked : AdEvents {}
    public class adCuepointsChanged : AdEvents {}
    public class adFirstQuartile : AdEvents {}
    public class adLoaded : AdEvents {}
    public class adLog : AdEvents {}
    public class adMidpoint : AdEvents {}
    public class adPaused : AdEvents {}
    public class adResumed : AdEvents {}
    public class adSkipped : AdEvents {}
    public class adStarted : AdEvents {}
    public class adStreamLoaded : AdEvents {}
    public class adTapped : AdEvents {}
    public class adThirdQuartile : AdEvents {}
    
    public class adDidProgressToTime : AdEvents {
        public let mediaTime, totalTime: TimeInterval
        init(mediaTime: TimeInterval, totalTime: TimeInterval) {
            self.mediaTime = mediaTime
            self.totalTime = totalTime
        }
        
        public required init() {
            fatalError("init() has not been implemented")
        }
    }
    public class adDidRequestPause : AdEvents {}
    public class adDidRequestResume : AdEvents {}
    
    public class WebOpenerEvent : AdEvents {
        let webOpener: NSObject
        public init(webOpener: NSObject!) {
            self.webOpener = webOpener
        }
        public required init() {
            fatalError("init() has not been implemented")
        }
    }
    
    public class adWebOpenerWillOpenExternalBrowser : WebOpenerEvent {}
    public class adWebOpenerWillOpenInAppBrowser : WebOpenerEvent {}
    public class adWebOpenerDidOpenInAppBrowser : WebOpenerEvent {}
    public class adWebOpenerWillCloseInAppBrowser : WebOpenerEvent {}
    public class adWebOpenerDidCloseInAppBrowser : WebOpenerEvent {}

    public required override init() {}
}
