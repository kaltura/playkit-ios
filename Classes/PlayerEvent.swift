//
//  PlayerEvent.swift
//  Pods
//
//  Created by Eliza Sapir on 14/11/2016.
//
//
import Foundation

/// An PlayerEvent is a class used to reflect player events.
public class PlayerEvent: PKEvent {
    
    // All events EXCLUDING error. Assuming error events are treated differently.
    public static let allEventTypes: [PlayerEvent.Type] = [
        canPlay, durationChanged, ended, loadedMetadata,
        play, pause, playing, seeking, seeked, stateChanged,
        tracksAvailable, playbackParamsUpdated, error
    ]
    
    // MARK: - Player Events Static Reference
    
    /// Sent when enough data is available that the media can be played, at least for a couple of frames.
    public static let canPlay: PlayerEvent.Type = CanPlay.self
    /// The metadata has loaded or changed, indicating a change in duration of the media. This is sent, for example, when the media has loaded enough that the duration is known.
    public static let durationChanged: PlayerEvent.Type = DurationChanged.self
    /// Sent when playback completes.
    public static let ended: PlayerEvent.Type = Ended.self
    /// The media's metadata has finished loading; all attributes now contain as much useful information as they're going to.
    public static let loadedMetadata: PlayerEvent.Type = LoadedMetadata.self
    /// Sent when playback of the media starts after having been paused; that is, when playback is resumed after a prior pause event.
    public static let play: PlayerEvent.Type = Play.self
    /// Sent when playback is paused.
    public static let pause: PlayerEvent.Type = Pause.self
    /// Sent when the media begins to play (either for the first time, after having been paused, or after ending and then restarting).
    public static let playing: PlayerEvent.Type = Playing.self
    /// Sent when a seek operation begins.
    public static let seeking: PlayerEvent.Type = Seeking.self
    /// Sent when a seek operation completes.
    public static let seeked: PlayerEvent.Type = Seeked.self
    /// Sent when tracks available.
    public static let tracksAvailable: PlayerEvent.Type = TracksAvailable.self
    /// Sent when Playback Params Updated.
    public static let playbackParamsUpdated: PlayerEvent.Type = PlaybackParamsUpdated.self
    /// Sent when player state is changed.
    public static let stateChanged: PlayerEvent.Type = StateChanged.self
    
    /// Sent when an error occurs.
    public static let error: PlayerEvent.Type = Error.self
    /// Sent when an plugin error occurs.
    public static let pluginError: PlayerEvent.Type = PluginError.self
    
    // MARK: - Player Basic Events

    class CanPlay : PlayerEvent {}
    class DurationChanged : PlayerEvent {
        convenience init(duration: TimeInterval) {
            self.init([EventDataKeys.Duration : NSNumber(value: duration)])
        }
    }
    
    class Ended : PlayerEvent {}
    class LoadedMetadata : PlayerEvent {}
    class Play : PlayerEvent {}
    class Pause : PlayerEvent {}
    class Playing : PlayerEvent {}
    class Seeking : PlayerEvent {}
    class Seeked : PlayerEvent {}
    
    class Error: PlayerEvent {
        convenience init(nsError: NSError) {
            self.init([EventDataKeys.Error : nsError])
        }
    }
    
    class PluginError: PlayerEvent {
        convenience init(nsError: NSError) {
            self.init([EventDataKeys.Error : nsError])
        }
    }
    
    // MARK: - Player Tracks Events
    
    class TracksAvailable : PlayerEvent {
        convenience init(tracks: PKTracks) {
            self.init([EventDataKeys.Tracks : tracks])
        }
    }
    
    class PlaybackParamsUpdated : PlayerEvent {
        convenience init(currentBitrate: Double) {
            self.init([EventDataKeys.CurrentBitrate : NSNumber(value: currentBitrate)])
        }
    }
    
    // MARK: - Player State Events

    class StateChanged : PlayerEvent {
        convenience init(newState: PlayerState, oldState: PlayerState) {
            self.init([EventDataKeys.NewState : newState as AnyObject,
                        EventDataKeys.OldState : oldState as AnyObject])
        }
    }
}

// MARK: - Ad Events

public class AdEvent: PKEvent {
    public static let allEventTypes: [AdEvent.Type] = [
        adBreakReady, adBreakEnded, adBreakStarted, adAllCompleted, adComplete, adClicked, adCuepointsChanged, adFirstQuartile, adLoaded, adLog, adMidpoint, adPaused, adResumed, adSkipped, adStarted, adStreamLoaded, adTapped, adThirdQuartile, adDidProgressToTime, adDidRequestPause, adDidRequestResume, adWebOpenerWillOpenExternalBrowser, adWebOpenerWillOpenInAppBrowser, adWebOpenerDidOpenInAppBrowser, adWebOpenerWillCloseInAppBrowser, adWebOpenerDidCloseInAppBrowser
    ]
    
    public static let adBreakReady: AdEvent.Type = AdBreakReady.self
    public static let adBreakEnded: AdEvent.Type = AdBreakEnded.self
    public static let adBreakStarted: AdEvent.Type = AdBreakStarted.self
    public static let adAllCompleted: AdEvent.Type = AdAllCompleted.self
    public static let adComplete: AdEvent.Type = AdComplete.self
    public static let adClicked: AdEvent.Type = AdClicked.self
    public static let adCuepointsChanged: AdEvent.Type = AdCuepointsChanged.self
    public static let adFirstQuartile: AdEvent.Type = AdFirstQuartile.self
    public static let adLoaded: AdEvent.Type = AdLoaded.self
    public static let adLog: AdEvent.Type = AdLog.self
    public static let adMidpoint: AdEvent.Type = AdMidpoint.self
    public static let adPaused: AdEvent.Type = AdPaused.self
    public static let adResumed: AdEvent.Type = AdResumed.self
    public static let adSkipped: AdEvent.Type = AdSkipped.self
    public static let adStarted: AdEvent.Type = AdStarted.self
    public static let adStreamLoaded: AdEvent.Type = AdStreamLoaded.self
    public static let adTapped: AdEvent.Type = AdTapped.self
    public static let adThirdQuartile: AdEvent.Type = AdThirdQuartile.self
    public static let adDidProgressToTime: AdEvent.Type = AdDidProgressToTime.self
    public static let adDidRequestPause: AdEvent.Type = AdDidRequestPause.self
    public static let adDidRequestResume: AdEvent.Type = AdDidRequestResume.self
    public static let webOpenerEvent: AdEvent.Type = WebOpenerEvent.self
    public static let adWebOpenerWillOpenExternalBrowser: AdEvent.Type = AdWebOpenerWillOpenExternalBrowser.self
    public static let adWebOpenerWillOpenInAppBrowser: AdEvent.Type = AdWebOpenerWillOpenInAppBrowser.self
    public static let adWebOpenerDidOpenInAppBrowser: AdEvent.Type = AdWebOpenerDidOpenInAppBrowser.self
    public static let adWebOpenerWillCloseInAppBrowser: AdEvent.Type = AdWebOpenerWillCloseInAppBrowser.self
    public static let adWebOpenerDidCloseInAppBrowser: AdEvent.Type = AdWebOpenerDidCloseInAppBrowser.self
    /// Sent when an error occurs.
    public static let error: AdEvent.Type = Error.self
    
    class AdBreakReady : AdEvent {}
    class AdBreakEnded : AdEvent {}
    class AdBreakStarted : AdEvent {}
    class AdAllCompleted : AdEvent {}
    class AdComplete : AdEvent {}
    class AdClicked : AdEvent {}
    class AdCuepointsChanged : AdEvent {}
    class AdFirstQuartile : AdEvent {}
    class AdLoaded : AdEvent {}
    class AdLog : AdEvent {}
    class AdMidpoint : AdEvent {}
    class AdPaused : AdEvent {}
    class AdResumed : AdEvent {}
    class AdSkipped : AdEvent {}
    class AdStarted : AdEvent {}
    class AdStreamLoaded : AdEvent {}
    class AdTapped : AdEvent {}
    class AdThirdQuartile : AdEvent {}
    
    class Error: AdEvent {
        convenience init(nsError: NSError) {
            self.init([AdEventDataKeys.Error : nsError])
        }
    }
    
    class AdDidProgressToTime : AdEvent {
        convenience init(mediaTime: TimeInterval, totalTime: TimeInterval) {
            self.init([AdEventDataKeys.MediaTime: NSNumber(value: mediaTime),
                        AdEventDataKeys.TotalTime: NSNumber(value: totalTime)])
        }
    }

    class AdDidRequestPause : AdEvent {}
    class AdDidRequestResume : AdEvent {}
    
    class WebOpenerEvent : AdEvent {
        convenience init(webOpener: NSObject!) {
            self.init([AdEventDataKeys.WebOpener: webOpener])
        }
    }
    
    class AdWebOpenerWillOpenExternalBrowser : WebOpenerEvent {}
    class AdWebOpenerWillOpenInAppBrowser : WebOpenerEvent {}
    class AdWebOpenerDidOpenInAppBrowser : WebOpenerEvent {}
    class AdWebOpenerWillCloseInAppBrowser : WebOpenerEvent {}
    class AdWebOpenerDidCloseInAppBrowser : WebOpenerEvent {}
}
