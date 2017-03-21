//
//  PKEvent.swift
//  Pods
//
//  Created by Eliza Sapir on 14/11/2016.
//
//

import Foundation
import AVFoundation

/// PKEvent
@objc public class PKEvent: NSObject {
    // Events that have payload must provide it as a dictionary for objective-c compat.
    @objc public let data: [String: Any]?
    
    @objc public required init(_ data: [String: Any]? = nil) {
        self.data = data
    }
}

// MARK: - PKEvent Data Accessors Extension
extension PKEvent {
    // MARK: - Event Data Keys
    struct EventDataKeys {
        static let Duration = "duration"
        static let Tracks = "tracks"
        static let CurrentBitrate = "currentBitrate"
        static let OldState = "oldState"
        static let NewState = "newState"
        static let Error = "error"
        static let Metadata = "metadata"
    }
    
    // MARK: Player Data Accessors
    
    /// Duration Value, PKEvent Data Accessor
    @objc public var duration: NSNumber? {
        return self.data?[EventDataKeys.Duration] as? NSNumber
    }
    
    /// Tracks Value, PKEvent Data Accessor
    @objc public var tracks: PKTracks? {
        return self.data?[EventDataKeys.Tracks] as? PKTracks
    }
    
    /// Current Bitrate Value, PKEvent Data Accessor
    @objc public var currentBitrate: NSNumber? {
        return self.data?[EventDataKeys.CurrentBitrate] as? NSNumber
    }
    
    /// Current Old State Value, PKEvent Data Accessor
    @objc public var oldState: PlayerState {
        guard let oldState = self.data?[EventDataKeys.OldState] as? PlayerState else {
            return PlayerState.unknown
        }
        
        return oldState
    }
    
    /// Current New State Value, PKEvent Data Accessor
    @objc public var newState: PlayerState {
        guard let newState = self.data?[EventDataKeys.NewState] as? PlayerState else {
            return PlayerState.unknown
        }
        
        return newState
    }
    
    /// Associated error from error event, PKEvent Data Accessor
    @objc public var error: NSError? {
        return self.data?[EventDataKeys.Error] as? NSError
    }
    
    /// Associated metadata from the event, PKEvent Data Accessor
    @objc public var timedMetadata: [AVMetadataItem]? {
        return self.data?[EventDataKeys.Metadata] as? [AVMetadataItem]
    }
}
