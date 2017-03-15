//
//  PlayerConfig.swift
//  PlayKit
//
//  Created by Noam Tamim on 09/10/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

import Foundation

/// A `MediaConfig` object defines behavior and info to use when preparing a `Player` object.
@objc public class MediaConfig: NSObject {

    @objc public var mediaEntry: MediaEntry
    @objc public var startTime: TimeInterval = 0
    
    @objc public override var description: String {
        return "Media config, mediaEntry: \(self.mediaEntry)\nstartTime: \(self.startTime)"
    }
    
    @objc public init(mediaEntry: MediaEntry, startTime: TimeInterval = 0) {
        self.mediaEntry = mediaEntry
        self.startTime = startTime
    }
    
    @objc public static func config(mediaEntry: MediaEntry) -> MediaConfig {
        return MediaConfig.init(mediaEntry: mediaEntry)
    }
    
    @objc public static func config(mediaEntry: MediaEntry, startTime: TimeInterval) -> MediaConfig {
        return MediaConfig.init(mediaEntry: mediaEntry, startTime: startTime)
    }
    
    /// Private init.
    private override init() {
        fatalError("Private initializer, use `init(mediaEntry:startTime:)`")
    }
}

/// A `PluginConfig` object defines config to use when loading a plugin object.
@objc public class PluginConfig: NSObject {
    /// Plugins config dictionary holds [plugin name : plugin config]
    @objc public var config: [String: Any]
    
    public override var description: String {
        return "Plugin config:\n\(self.config)"
    }
    
    @objc public init(config: [String: Any]) {
        self.config = config
    }
    
    /// Private init.
    private override init() {
        fatalError("Private initializer, use `init(config:)`")
    }
}

extension PluginConfig: NSCopying {
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = PluginConfig(config: config)
        return copy
    }
}




