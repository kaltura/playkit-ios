//
//  PlayerConfig.swift
//  PlayKit
//
//  Created by Noam Tamim on 09/10/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

import Foundation

/// A `MediaConfig` object defines behavior and info to use when preparing a `Player` object.
public class MediaConfig: NSObject {
    public var mediaEntry: MediaEntry
    public var startTime: TimeInterval = 0
    
    override public var description: String {
        return "Media config, mediaEntry: \(self.mediaEntry)\nstartTime: \(self.startTime)"
    }
    
    public init(mediaEntry: MediaEntry, startTime: TimeInterval = 0) {
        self.mediaEntry = mediaEntry
        self.startTime = startTime
    }
    
    public static func config(mediaEntry: MediaEntry) -> MediaConfig {
        return MediaConfig.init(mediaEntry: mediaEntry)
    }
    
    public static func config(mediaEntry: MediaEntry, startTime: TimeInterval) -> MediaConfig {
        return MediaConfig.init(mediaEntry: mediaEntry, startTime: startTime)
    }
    
    /// Private init.
    private override init() {
        fatalError("Private initializer, use `init(mediaEntry:startTime:)`")
    }
}

/// A `PluginConfig` object defines config to use when loading a plugin object.
public class PluginConfig: NSObject {
    /// Plugins config dictionary holds [plugin name : plugin config]
    @objc public var config: [String : Any]
    
    public init(config: [String : Any]) {
        self.config = config
    }
    
    override public var description: String {
        return "Plugin config:\n\(self.config)"
    }
}




