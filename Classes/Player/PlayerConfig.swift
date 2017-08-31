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

extension MediaConfig: NSCopying {
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = MediaConfig(mediaEntry: self.mediaEntry, startTime: self.startTime)
        return copy
    }
}

/// A `PluginConfig` object defines config to use when loading a plugin object.
@objc public class PKPluginConfigs: NSObject {
    /// Plugins config dictionary holds [plugin name : plugin config]
    @objc public var configs = [String: Any]()
    
    public override var description: String {
        return "Plugin config: \(self.configs)"
    }
    
    /// adds a config on the provided plugin name.
    @objc public func add(pluginName: String, config: Any) {
        self.configs[pluginName] = config
    }
    
    /// remove config from the provided plugin name.
    @objc public func remove(pluginName: String) {
        self.configs[pluginName] = nil
    }
}

extension PKPluginConfigs: NSCopying {
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = PKPluginConfigs()
        copy.configs = self.configs
        return copy
    }
}




