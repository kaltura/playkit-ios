//
//  File.swift
//  Pods
//
//  Created by Eliza Sapir on 25/01/2017.
//
//

import Foundation

/// NSDictionary+EventName
public extension NSDictionary {
    /**
     Extracts value from the dictionary.
     :param: key Key to check
     :returns: value
     */
    private func valueForEventName (_ key: String) -> Any {
        return self[key]
    }
    
    /**
     Duration Value
     :returns: TimeInterval
     */
    public func durationValue() -> TimeInterval {
        return self.valueForEventName(kDuration) as! TimeInterval
    }
    
    /**
     Tracks Value
     :returns: PKTracks
     */
    public func tracksValue() -> PKTracks {
        return self.valueForEventName(kTracks) as! PKTracks
    }
    
    /**
     Current Bitrate Value
     :returns: Double
     */
    public func currentBitrateValue() -> Double {
        return self.valueForEventName(kCurrentBitrate) as! Double
    }
    
    /**
     Current Old State Value
     :returns: PlayerState
     */
    public func oldStateValue() -> PlayerState {
        return self.valueForEventName(kOldState) as! PlayerState
    }
    
    /**
     Current New State Value
     :returns: PlayerState
     */
    public func newStateValue() -> PlayerState {
        return self.valueForEventName(kNewState) as! PlayerState
    }
}
