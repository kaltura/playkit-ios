//
//  PlayerEvent.swift
//  Pods
//
//  Created by Eliza Sapir on 14/11/2016.
//
//
import Foundation
import AVFoundation

/// PlayerEvent is a class used to reflect player events.
@objc public class PlayerEvent: PKEvent {
    
    // All events EXCLUDING error. Assuming error events are treated differently.
    @objc public static let allEventTypes: [PlayerEvent.Type] = [
        canPlay, durationChanged, ended, loadedMetadata,
        play, pause, playing, seeking, seeked, stateChanged,
        tracksAvailable, playbackInfo, error
    ]
    
    // MARK: - Player Events Static Reference
    
    /// Sent when enough data is available that the media can be played, at least for a couple of frames.
    @objc public static let canPlay: PlayerEvent.Type = CanPlay.self
    /// The metadata has loaded or changed, indicating a change in duration of the media. This is sent, for example, when the media has loaded enough that the duration is known.
    @objc public static let durationChanged: PlayerEvent.Type = DurationChanged.self
    /// Sent when playback stopped.
    @objc public static let stopped: PlayerEvent.Type = Stopped.self
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
    @objc public static let playbackInfo: PlayerEvent.Type = PlaybackInfo.self
    /// Sent when player state is changed.
    @objc public static let stateChanged: PlayerEvent.Type = StateChanged.self
    /// Sent when timed metadata is available.
    @objc public static let timedMetadata: PlayerEvent.Type = TimedMetadata.self
    /// Sent when source was selected.
    @objc public static let sourceSelected: PlayerEvent.Type = SourceSelected.self
    
    /// Sent when an error occurs.
    @objc public static let error: PlayerEvent.Type = Error.self
    /// Sent when an plugin error occurs.
    @objc public static let pluginError: PlayerEvent.Type = PluginError.self
    /// Sent when an error log event received from player.
    @objc public static let errorLog: PlayerEvent.Type = ErrorLog.self
    
    // MARK: - Player Basic Events

    class CanPlay: PlayerEvent {}
    class DurationChanged: PlayerEvent {
        convenience init(duration: TimeInterval) {
            self.init([EventDataKeys.duration: NSNumber(value: duration)])
        }
    }
    
    class Stopped: PlayerEvent {}
    class Ended: PlayerEvent {}
    class LoadedMetadata: PlayerEvent {}
    class Play: PlayerEvent {}
    class Pause: PlayerEvent {}
    class Playing: PlayerEvent {}
    class Seeking: PlayerEvent {}
    class Seeked: PlayerEvent {}
    
    class SourceSelected: PlayerEvent {
        convenience init(contentURL: URL?) {
            self.init([EventDataKeys.contentURL: contentURL])
        }
    }
    
    class Error: PlayerEvent {
        convenience init(nsError: NSError) {
            self.init([EventDataKeys.error: nsError])
        }
        
        convenience init(error: PKError) {
            self.init([EventDataKeys.error: error.asNSError])
        }
    }
    
    class PluginError: PlayerEvent {
        convenience init(nsError: NSError) {
            self.init([EventDataKeys.error: nsError])
        }
        
        convenience init(error: PKError) {
            self.init([EventDataKeys.error: error.asNSError])
        }
    }
    
    class ErrorLog: PlayerEvent {
        convenience init(nsError: NSError) {
            self.init([EventDataKeys.error: nsError])
        }
        
        convenience init(error: PKError) {
            self.init([EventDataKeys.error: error.asNSError])
        }
    }
    
    class TimedMetadata: PlayerEvent {
        convenience init(metadata: [AVMetadataItem]) {
            self.init([EventDataKeys.metadata: metadata])
        }
    }
    
    // MARK: - Player Tracks Events
    
    class TracksAvailable: PlayerEvent {
        convenience init(tracks: PKTracks) {
            self.init([EventDataKeys.tracks : tracks])
        }
    }
    
    class PlaybackInfo: PlayerEvent {
        convenience init(playbackInfo: PKPlaybackInfo) {
            self.init([EventDataKeys.playbackInfo: playbackInfo])
        }
    }
    
    // MARK: - Player State Events

    class StateChanged: PlayerEvent {
        convenience init(newState: PlayerState, oldState: PlayerState) {
            self.init([EventDataKeys.newState : newState as AnyObject,
                       EventDataKeys.oldState : oldState as AnyObject])
        }
    }
}
