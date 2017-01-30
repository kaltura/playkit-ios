//
//  PKEvent.swift
//  Pods
//
//  Created by Eliza Sapir on 14/11/2016.
//
//

import Foundation

/// PKEvent
public class PKEvent: NSObject {
    // Events that have payload must provide it as a dictionary for objective-c compat.
    public let data: [String : AnyObject]?
    
    public required init(_ data: [String : AnyObject]? = nil) {
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
    }
    
    // MARK: Player Data Accessors
    
    /// Duration Value, PKEvent Data Accessor
    public var duration: NSNumber? {
        return self.data?[EventDataKeys.Duration] as? NSNumber
    }
    
    /// Tracks Value, PKEvent Data Accessor
    public var tracks: PKTracks? {
        return self.data?[EventDataKeys.Tracks] as? PKTracks
    }
    
    /// Current Bitrate Value, PKEvent Data Accessor
    public var currentBitrate: NSNumber? {
        return self.data?[EventDataKeys.CurrentBitrate] as? NSNumber
    }
    
    /// Current Old State Value, PKEvent Data Accessor
    public var oldState: PlayerState {
        guard let oldState = self.data?[EventDataKeys.OldState] as? PlayerState else {
            return PlayerState.unknown
        }
        
        return oldState
    }
    
    /// Current New State Value, PKEvent Data Accessor
    public var newState: PlayerState {
        guard let newState = self.data?[EventDataKeys.NewState] as? PlayerState else {
            return PlayerState.unknown
        }
        
        return newState
    }
    
    /// Associated error from error event, PKEvent Data Accessor
    public var error: NSError? {
        return self.data?[EventDataKeys.Error] as? NSError
    }
    
    // MARK: - Ad Data Keys
    struct AdEventDataKeys {
        static let MediaTime = "mediaTime"
        static let TotalTime = "totalTime"
        static let WebOpener = "webOpener"
    }
    
    // MARK: Ad Data Accessors
    
    /// MediaTime, PKEvent Ad Data Accessor
    public var mediaTime: NSNumber? {
        return self.data?[AdEventDataKeys.MediaTime] as? NSNumber
    }
    
    /// TotalTime, PKEvent Ad Data Accessor
    public var totalTime: NSNumber? {
        return self.data?[AdEventDataKeys.TotalTime] as? NSNumber
    }
    
    /// WebOpener, PKEvent Ad Data Accessor
    public var webOpener: NSObject? {
        return self.data?[AdEventDataKeys.WebOpener] as? NSObject
    }
}
