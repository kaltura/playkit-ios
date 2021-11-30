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

/// PKEvent
@objc open class PKEvent: NSObject {
    // Events that have payload must provide it as a dictionary for objective-c compat.
    @objc public let data: [String: Any]?
    
    @objc public required init(_ data: [String: Any]? = nil) {
        self.data = data
        super.init()
    }
    
    public private(set) lazy var namespace: String = {
        var namespace = ""
        var mirror: Mirror? = Mirror(reflecting: self)
        while let m = mirror, m.subjectType != PKEvent.self && m.subjectType != NSObject.self {
            namespace = namespace == "" ? String(describing: m.subjectType) : "\(String(describing: m.subjectType))." + namespace
            mirror = m.superclassMirror
        }
        return namespace
    }()
    
    open override var description: String {
        get {
            return self.namespace
        }
    }
}

// MARK: - PKEvent Data Accessors Extension
public extension PKEvent {
    // MARK: - Event Data Keys
    struct EventDataKeys {
        static let duration = "duration"
        static let targetSeekPosition = "targetSeekPosition"
        static let tracks = "tracks"
        static let selectedTrack = "selectedTrack"
        static let playbackInfo = "playbackInfo"
        static let oldState = "oldState"
        static let newState = "newState"
        static let error = "error"
        static let metadata = "metadata"
        static let mediaSource = "mediaSource"
        static let timeRanges = "timeRanges"
        static let bitrate = "bitrate"
        static let currentTime = "currentTime"
        static let rate = "rate"
        static let entryId = "entryId"
    }
    
    // MARK: Player Data Accessors
    
    /// Duration Value, PKEvent Data Accessor
    @objc var duration: NSNumber? {
        return self.data?[EventDataKeys.duration] as? NSNumber
    }
    
    /// Current Time Value, PKEvent Data Accessor
    @objc var currentTime: NSNumber? {
        return self.data?[EventDataKeys.currentTime] as? NSNumber
    }
    
    /// Duration Value, PKEvent Data Accessor
    @objc var targetSeekPosition: NSNumber? {
        return self.data?[EventDataKeys.targetSeekPosition] as? NSNumber
    }
    
    /// Tracks Value, PKEvent Data Accessor
    @objc var tracks: PKTracks? {
        return self.data?[EventDataKeys.tracks] as? PKTracks
    }
    
    /// Selected Track Value, PKEvent Data Accessor
    @objc var selectedTrack: Track? {
        return self.data?[EventDataKeys.selectedTrack] as? Track
    }
    
    /// Indicated Bitrate, PKEvent Data Accessor
    @objc var bitrate: NSNumber? {
        return self.data?[EventDataKeys.bitrate] as? NSNumber
    }
    
    /// The PlaybackInfo object, PKEvent Data Accessor
    @objc var playbackInfo: PKPlaybackInfo? {
        return self.data?[EventDataKeys.playbackInfo] as? PKPlaybackInfo
    }
    
    /// Indicated Palyback Rate, PKEvent Data Accessor
    @objc var palybackRate: NSNumber? {
        return self.data?[EventDataKeys.rate] as? NSNumber
    }
    
    /// Current Old State Value, PKEvent Data Accessor
    @objc var oldState: PlayerState {
        guard let oldState = self.data?[EventDataKeys.oldState] as? PlayerState else {
            return PlayerState.unknown
        }
        
        return oldState
    }
    
    /// Current New State Value, PKEvent Data Accessor
    @objc var newState: PlayerState {
        guard let newState = self.data?[EventDataKeys.newState] as? PlayerState else {
            return PlayerState.unknown
        }
        
        return newState
    }
    
    /// Associated error from error event, PKEvent Data Accessor
    @objc var error: NSError? {
        return self.data?[EventDataKeys.error] as? NSError
    }
    
    /// Associated metadata from the event, PKEvent Data Accessor
    @objc var timedMetadata: [AVMetadataItem]? {
        return self.data?[EventDataKeys.metadata] as? [AVMetadataItem]
    }
    
    /// The MediaSource object, PKEvent Data Accessor
    @objc var mediaSource: PKMediaSource? {
        return self.data?[EventDataKeys.mediaSource] as? PKMediaSource
    }
    
    /// The loaded time ranges, PKEvent Data Accessor
    @objc var timeRanges: [PKTimeRange]? {
        return self.data?[EventDataKeys.timeRanges] as? [PKTimeRange]
    }
    
    /// Media Entry id, PKEvent Data Accessor
    @objc var entryId: String? {
        return self.data?[EventDataKeys.entryId] as? String
    }
}
