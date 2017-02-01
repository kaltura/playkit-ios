//
//  PlayerConfig.swift
//  PlayKit
//
//  Created by Noam Tamim on 09/10/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

import Foundation

/// A `PlayerConfig` object defines behavior and info to use when loading a `Player` object.
public class PlayerConfig: NSObject {
    public var mediaEntry : MediaEntry?
    public var startTime : TimeInterval = 0
    
    // Builders
    @discardableResult
    public func set(mediaEntry: MediaEntry) -> Self {
        self.mediaEntry = mediaEntry
        return self
    }
       
    @discardableResult 
    public func set(startTime: TimeInterval) -> Self {
        self.startTime = startTime
        return self
    }
}

public class PluginConfig: NSObject {
    public var config = [String : AnyObject]()
    subscript(idx: String) -> AnyObject? {
        get {
            return self.config[idx]
        }
        set {
            self.config[idx] = newValue
        }
    }
}




