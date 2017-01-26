//
//  PlayerEvent.swift
//  Pods
//
//  Created by Eliza Sapir on 14/11/2016.
//
//
import Foundation

// MARK: - Event Data Keys
struct EventDataKeys {
    static let Duration = "duration"
    static let Tracks = "tracks"
    static let CurrentBitrate = "currentBitrate"
    static let OldState = "oldState"
    static let NewState = "newState"
}

/// An PlayerEvent is a class used to reflect player events.

public class PlayerEvent: PKEvent {
    
    // All events EXCLUDING error. Assuming error events are treated differently.
    public static let allEventTypes: [PlayerEvent.Type] = [
        canPlay, durationChanged, ended, loadedMetadata,
        play, paused, playing, seeking, seeked, stateChanged
    ]
    
    // MARK: - Player Events Static Reference
    
    /// Sent when enough data is available that the media can be played, at least for a couple of frames.
    @objc public static let canPlay = CanPlay.self
    /// The metadata has loaded or changed, indicating a change in duration of the media. This is sent, for example, when the media has loaded enough that the duration is known.
    @objc public static let durationChanged = DurationChanged.self
    /// Sent when playback completes.
    @objc public static let ended = Ended.self
    /// The media's metadata has finished loading; all attributes now contain as much useful information as they're going to.
    @objc public static let loadedMetadata = LoadedMetadata.self
    /// Sent when an error occurs.
    @objc public static let error = Error.self
    /// Sent when playback of the media starts after having been paused; that is, when playback is resumed after a prior pause event.
    @objc public static let play = Play.self
    /// Sent when playback is paused.
    @objc public static let paused = Paused.self
    /// Sent when the media begins to play (either for the first time, after having been paused, or after ending and then restarting).
    @objc public static let playing = Playing.self
    /// Sent when a seek operation begins.
    @objc public static let seeking = Seeking.self
    /// Sent when a seek operation completes.
    @objc public static let seeked = Seeked.self
    /// Sent when tracks available.
    @objc public static let tracksAvailable = TracksAvailable.self
    /// Sent when Playback Params Updated.
    @objc public static let playbackParamsUpdated = PlaybackParamsUpdated.self
    /// Sent when player state is changed.
    @objc public static let stateChanged = StateChanged.self
    
    // MARK: - Player Basic Events

    public class CanPlay : PlayerEvent {}
    public class DurationChanged : PlayerEvent {
        public var duration: TimeInterval
        
        init(duration: TimeInterval) {
            self.duration = duration
        }
        
        override public func data() -> [String : AnyObject]? {
            return [EventDataKeys.Duration: NSNumber(value: duration)]
        }
    }
    
    public class Ended : PlayerEvent {}
    public class LoadedMetadata : PlayerEvent {}
    public class Error : PlayerEvent {}
    public class Play : PlayerEvent {}
    public class Paused : PlayerEvent {}
    public class Playing : PlayerEvent {}
    public class Seeking : PlayerEvent {}
    public class Seeked : PlayerEvent {}
    
    // MARK: - Player Tracks Events
    
    public class TracksAvailable : PlayerEvent {
        public var tracks: PKTracks
        
        public init(tracks: PKTracks) {
            self.tracks = tracks
        }
        
        override public func data() -> [String : AnyObject]? {
            return [EventDataKeys.Tracks: tracks]
        }
    }
    
    public class PlaybackParamsUpdated : PlayerEvent {
        public var currentBitrate: Double
        
        init(currentBitrate: Double) {
            self.currentBitrate = currentBitrate
        }
        
        override public func data() -> [String : AnyObject]? {
            return [EventDataKeys.CurrentBitrate: NSNumber(value: currentBitrate)]
        }
    }
    
    // MARK: - Player State Events

    public class StateChanged : PlayerEvent {
        public var newState: PlayerState
        public var oldState: PlayerState
        
        public init(newState: PlayerState, oldState: PlayerState) {
            self.newState = newState
            self.oldState = oldState
        }
        
        override public func data() -> [String : AnyObject]? {
            return [EventDataKeys.NewState: newState as AnyObject, EventDataKeys.OldState: oldState as AnyObject]
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
