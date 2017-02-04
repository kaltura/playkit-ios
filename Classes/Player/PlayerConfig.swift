//
//  PlayerConfig.swift
//  PlayKit
//
//  Created by Noam Tamim on 09/10/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

import Foundation

/// A `PlayerConfig` object defines mediaConfig and pluginConfig composite object.
public class PlayerConfig: NSObject {
    public var mediaConfig = MediaConfig()
    public var pluginConfig = PluginConfig()
    
    public init(mediaConfig: MediaConfig, pluginConfig: PluginConfig) {
        self.mediaConfig = mediaConfig
        self.pluginConfig = pluginConfig
    }
}

/// A `MediaConfig` object defines behavior and info to use when preparing a `Player` object.
public class MediaConfig: NSObject {
    public var mediaEntry: MediaEntry?
    public var startTime: TimeInterval = 0
    
    override public var description: String {
        return "Media config, mediaEntry: \(self.mediaEntry)\nstartTime: \(self.startTime)"
    }
    
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

/// A `PluginConfig` object defines config to use when loading a plugin object.
public class PluginConfig: NSObject {
    /// Plugins congfig dictionary holds [plugin name : plugin config]
    public var config: [String : AnyObject]?
    
    @discardableResult
    public func set(config: [String : AnyObject]) -> Self {
        self.config = config
        return self
    }
    
    override public var description: String {
        return "Plugin config:\n\(self.config)"
    }
}




