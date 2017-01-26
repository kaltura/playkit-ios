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
    public let data: [String: AnyObject]?
    
    public init(_ data: [String: AnyObject]? = nil) {
        self.data = data
    }
}

// MARK: - Data Accessors
extension PKEvent {
    /// Duration Value
    public var eventDuration: NSNumber? {
        return self.data?[EventDataKeys.Duration] as? NSNumber
    }
    
    /// Tracks Value
    public var eventTracks: PKTracks? {
        return self.data?[EventDataKeys.Tracks] as? PKTracks
    }
    
    /// Current Bitrate Value
    public var eventCurrentBitrate: NSNumber? {
        return self.data?[EventDataKeys.CurrentBitrate] as? NSNumber
    }
    
    /// Current Old State Value
    public var eventOldState: PlayerState {
        guard let oldState = self.data?[EventDataKeys.OldState] as? PlayerState else {
            return PlayerState.unknown
        }
        
        return oldState
    }
    
    /// Current New State Value
    public var eventNewState: PlayerState {
        guard let newState = self.data?[EventDataKeys.NewState] as? PlayerState else {
            return PlayerState.unknown
        }
        
        return newState
    }
}
