// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import Foundation
import AVFoundation

/// PlayerEvent is a class used to reflect player events.
@objc public class PlayerEvent: PKEvent {
    
    // All events EXCLUDING error. Assuming error events are treated differently.
    @objc public static let allEventTypes: [PlayerEvent.Type] = [
        canPlay, durationChanged, ended, loadedMetadata,
        play, pause, playing, seeking, seeked, stateChanged, playbackInfo,
        tracksAvailable, textTrackChanged, audioTrackChanged, videoTrackChanged, error
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
    /// Sent when text track has been changed.
    @objc public static let textTrackChanged: PlayerEvent.Type = TextTrackChanged.self
    /// Sent when audio track has been changed.
    @objc public static let audioTrackChanged: PlayerEvent.Type = AudioTrackChanged.self
    /// Sent when video track has been changed.
    @objc public static let videoTrackChanged: PlayerEvent.Type = VideoTrackChanged.self
    /// Sent when Playback Params Updated.
    @objc public static let playbackInfo: PlayerEvent.Type = PlaybackInfo.self
    /// Sent when player state is changed.
    @objc public static let stateChanged: PlayerEvent.Type = StateChanged.self
    /// Sent when timed metadata is available.
    @objc public static let timedMetadata: PlayerEvent.Type = TimedMetadata.self
    /// Sent when source was selected.
    @objc public static let sourceSelected: PlayerEvent.Type = SourceSelected.self
    /// Sent when loaded time ranges was changed, loaded time ranges represent the buffered content.
    /// could be used to show amount buffered on the playhead UI.
    @objc public static let loadedTimeRanges: PlayerEvent.Type = LoadedTimeRanges.self

    /// Sent when an error occurs in the player that the playback can recover from.
    @objc public static let error: PlayerEvent.Type = Error.self
    /// Sent when a plugin error occurs.
    @objc public static let pluginError: PlayerEvent.Type = PluginError.self
    /// Sent when an error log event received from player (non fatal errors).
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
    class Seeking: PlayerEvent {
        convenience init(targetSeekPosition: TimeInterval) {
            self.init([EventDataKeys.targetSeekPosition: NSNumber(value: targetSeekPosition)])
        }
    }
    class Seeked: PlayerEvent {}
    
    class SourceSelected: PlayerEvent {
        convenience init(mediaSource: PKMediaSource) {
            self.init([EventDataKeys.mediaSource: mediaSource])
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
    
    class TracksAvailable: PlayerEvent {
        convenience init(tracks: PKTracks) {
            self.init([EventDataKeys.tracks: tracks])
        }
    }
    
    class TextTrackChanged: PlayerEvent {
        convenience init(track: Track) {
            self.init([EventDataKeys.selectedTrack: track])
        }
    }
    
    class AudioTrackChanged: PlayerEvent {
        convenience init(track: Track) {
            self.init([EventDataKeys.selectedTrack: track])
        }
    }

    class VideoTrackChanged: PlayerEvent {
        convenience init(bitrate: Double) {
            self.init([EventDataKeys.bitrate: bitrate])
        }
    }

    class PlaybackInfo: PlayerEvent {
        convenience init(playbackInfo: PKPlaybackInfo) {
            self.init([EventDataKeys.playbackInfo: playbackInfo])
        }
    }
    
    class StateChanged: PlayerEvent {
        convenience init(newState: PlayerState, oldState: PlayerState) {
            self.init([EventDataKeys.newState: newState as AnyObject,
                       EventDataKeys.oldState: oldState as AnyObject])
        }
    }
    
    class LoadedTimeRanges: PlayerEvent {
        convenience init(timeRanges: [PKTimeRange]) {
            self.init([EventDataKeys.timeRanges: timeRanges])
        }
    }
}
