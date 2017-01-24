//
//  ObjCEventAdapter.swift
//  Pods
//
//  Created by Noam Tamim on 23/01/2017.
//
//

import UIKit

/// An BridgedPlayerEvent is a wrapper used to reflect player's events to applications written in Obj-C.

// MARK: - Player Basic Events

/// Sent when enough data is available that the media can be played, at least for a couple of frames.
public class PlayerEvent_canPlay: PKEvent, PKBridgedEvent {
    public required init(_ event: PKEvent) {}
    static let realType: PKEvent.Type = PlayerEvents.canPlay.self
}

/// The metadata has loaded or changed, indicating a change in duration of the media. This is sent, for example, when the media has loaded enough that the duration is known.
public class PlayerEvent_durationChanged: PKEvent, PKBridgedEvent {
    static let realType: PKEvent.Type = PlayerEvents.durationChange.self
    private let realEvent: PlayerEvents.durationChange
    
    public var duration: TimeInterval {
        return realEvent.duration
    }
    
    public required init(_ event: PKEvent) {
        self.realEvent = event as! PlayerEvents.durationChange
    }
}

/// Sent when playback completes.
public class PlayerEvent_ended: PKEvent, PKBridgedEvent {
    public required init(_ event: PKEvent) {}
    static let realType: PKEvent.Type = PlayerEvents.ended.self
}

/// The media's metadata has finished loading; all attributes now contain as much useful information as they're going to.
public class PlayerEvent_loadedMetadata: PKEvent, PKBridgedEvent {
    public required init(_ event: PKEvent) {}
    static let realType: PKEvent.Type = PlayerEvents.loadedMetadata.self
}

/// Sent when an error occurs.
public class PlayerEvent_error: PKEvent, PKBridgedEvent {
    public required init(_ event: PKEvent) {}
    static let realType: PKEvent.Type = PlayerEvents.error.self
}

/// Sent when playback of the media starts after having been paused; that is, when playback is resumed after a prior pause event.
public class PlayerEvent_play: PKEvent, PKBridgedEvent {
    public required init(_ event: PKEvent) {}
    static let realType: PKEvent.Type = PlayerEvents.play.self
}

/// Sent when playback is paused.
public class PlayerEvent_pause: PKEvent, PKBridgedEvent {
    public required init(_ event: PKEvent) {}
    static let realType: PKEvent.Type = PlayerEvents.pause.self
}

/// Sent when the media begins to play (either for the first time, after having been paused, or after ending and then restarting).
public class PlayerEvent_playing: PKEvent, PKBridgedEvent {
    public required init(_ event: PKEvent) {}
    static let realType: PKEvent.Type = PlayerEvents.playing.self
}

/// Sent when a seek operation begins.
public class PlayerEvent_seeking: PKEvent, PKBridgedEvent {
    public required init(_ event: PKEvent) {}
    static let realType: PKEvent.Type = PlayerEvents.seeking.self
}

/// Sent when a seek operation completes.
public class PlayerEvent_seeked: PKEvent, PKBridgedEvent {
    public required init(_ event: PKEvent) {}
    static let realType: PKEvent.Type = PlayerEvents.seeked.self
}

// MARK: - Player Tracks Events

/// Sent when tracks available.
public class PlayerEvent_tracksAvailable: PKEvent, PKBridgedEvent {
    static let realType: PKEvent.Type = PlayerEvents.tracksAvailable.self
    private let realEvent: PlayerEvents.tracksAvailable
    
    
    public var tracks: PKTracks {
        return realEvent.tracks
    }
    
    public required init(_ event: PKEvent) {
        self.realEvent = event as! PlayerEvents.tracksAvailable
    }
}

/// Sent when Playback Params Updated.
public class PlayerEvent_playbackParamsUpdated: PKEvent, PKBridgedEvent {
    static let realType: PKEvent.Type = PlayerEvents.playbackParamsUpdated.self
    private let realEvent: PlayerEvents.playbackParamsUpdated
    
    
    public var currentBitrate: Double {
        return realEvent.currentBitrate
    }
    
    public required init(_ event: PKEvent) {
        self.realEvent = event as! PlayerEvents.playbackParamsUpdated
    }
}

// MARK: - Player State Events

/// Sent when player state is changed.
public class PlayerEvent_stateChanged: PKEvent, PKBridgedEvent {
    static let realType: PKEvent.Type = PlayerEvents.stateChanged.self
    private let realEvent: PlayerEvents.stateChanged
    
    
    public var newState: PlayerState {
        return realEvent.newState
    }
    
    public var oldState: PlayerState {
        return realEvent.oldState
    }
    
    public required init(_ event: PKEvent) {
        self.realEvent = event as! PlayerEvents.stateChanged
    }
}

