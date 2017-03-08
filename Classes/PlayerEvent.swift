//
//  PlayerEvent.swift
//  Pods
//
//  Created by Eliza Sapir on 14/11/2016.
//
//
import Foundation

/// An PlayerEvent is a class used to reflect player events.
@objc public class PlayerEvent: PKEvent {
    
    // All events EXCLUDING error. Assuming error events are treated differently.
    @objc public static let allEventTypes: [PlayerEvent.Type] = [
        canPlay, durationChanged, ended, loadedMetadata,
        play, pause, playing, seeking, seeked, stateChanged,
        tracksAvailable, playbackParamsUpdated, error
    ]
    
    // MARK: - Player Events Static Reference
    
    /// Sent when enough data is available that the media can be played, at least for a couple of frames.
    @objc public static let canPlay: PlayerEvent.Type = CanPlay.self
    /// The metadata has loaded or changed, indicating a change in duration of the media. This is sent, for example, when the media has loaded enough that the duration is known.
    @objc public static let durationChanged: PlayerEvent.Type = DurationChanged.self
    /// Sent when playback completes.
    @objc public static let ended: PlayerEvent.Type = Ended.self
    /// The media's metadata has finished loading; all attributes now contain as much useful information as they're going to.
    @objc public static let loadedMetadata: PlayerEvent.Type = LoadedMetadata.self
    /// Sent when playback of the media starts after having been paused; that is, when playback is resumed after a prior pause event.
    @objc public static let play: PlayerEvent.Type = Play.self
    /// Sent when playback is paused.
    @objc public static let pause: PlayerEvent.Type = Pause.self
    /// Sent when the media begins to play (either for the first time, after having been paused, or after ending and then restarting).
    @objc public static let playing: PlayerEvent.Type = Playing.self
    /// Sent when a seek operation begins.
    @objc public static let seeking: PlayerEvent.Type = Seeking.self
    /// Sent when a seek operation completes.
    @objc public static let seeked: PlayerEvent.Type = Seeked.self
    /// Sent when tracks available.
    @objc public static let tracksAvailable: PlayerEvent.Type = TracksAvailable.self
    /// Sent when Playback Params Updated.
    @objc public static let playbackParamsUpdated: PlayerEvent.Type = PlaybackParamsUpdated.self
    /// Sent when player state is changed.
    @objc public static let stateChanged: PlayerEvent.Type = StateChanged.self
    
    /// Sent when an error occurs.
    @objc public static let error: PlayerEvent.Type = Error.self
    /// Sent when an plugin error occurs.
    @objc public static let pluginError: PlayerEvent.Type = PluginError.self
    
    // MARK: - Player Basic Events

    class CanPlay: PlayerEvent {}
    class DurationChanged: PlayerEvent {
        convenience init(duration: TimeInterval) {
            self.init([EventDataKeys.Duration: NSNumber(value: duration)])
        }
    }
    
    class Ended: PlayerEvent {}
    class LoadedMetadata: PlayerEvent {}
    class Play: PlayerEvent {}
    class Pause: PlayerEvent {}
    class Playing: PlayerEvent {}
    class Seeking: PlayerEvent {}
    class Seeked: PlayerEvent {}
    
    class Error: PlayerEvent {
        convenience init(nsError: NSError) {
            self.init([EventDataKeys.Error: nsError])
        }
        
        convenience init(error: PKError) {
            self.init([EventDataKeys.Error: error.asNSError])
        }
    }
    
    class PluginError: PlayerEvent {
        convenience init(nsError: NSError) {
            self.init([EventDataKeys.Error: nsError])
        }
        
        convenience init(error: PKError) {
            self.init([EventDataKeys.Error: error.asNSError])
        }
    }
    
    // MARK: - Player Tracks Events
    
    class TracksAvailable: PlayerEvent {
        convenience init(tracks: PKTracks) {
            self.init([EventDataKeys.Tracks : tracks])
        }
    }
    
    class PlaybackParamsUpdated: PlayerEvent {
        convenience init(currentBitrate: Double) {
            self.init([EventDataKeys.CurrentBitrate : NSNumber(value: currentBitrate)])
        }
    }
    
    // MARK: - Player State Events

    class StateChanged: PlayerEvent {
        convenience init(newState: PlayerState, oldState: PlayerState) {
            self.init([EventDataKeys.NewState : newState as AnyObject,
                        EventDataKeys.OldState : oldState as AnyObject])
        }
    }
}
