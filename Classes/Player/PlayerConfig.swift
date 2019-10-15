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

    @objc public var mediaEntry: PKMediaEntry
    @objc public var startTime: TimeInterval = TimeInterval.nan
    
    @objc public override var description: String {
        return "Media config, mediaEntry: \(self.mediaEntry)\nstartTime: \(self.startTime)"
    }
    
    @objc public init(mediaEntry: PKMediaEntry) {
        self.mediaEntry = mediaEntry
    }
    
    @objc public init(mediaEntry: PKMediaEntry, startTime: TimeInterval) {
        self.mediaEntry = mediaEntry
        self.startTime = startTime
    }
    
    @objc public static func config(mediaEntry: PKMediaEntry) -> MediaConfig {
        return MediaConfig.init(mediaEntry: mediaEntry)
    }
    
    @objc public static func config(mediaEntry: PKMediaEntry, startTime: TimeInterval) -> MediaConfig {
        return MediaConfig.init(mediaEntry: mediaEntry, startTime: startTime)
    }
    
    /// Private init.
    private override init() {
        fatalError("Private initializer, use `init(mediaEntry:startTime:)`")
    }
}

extension MediaConfig: NSCopying {
    
    @objc public func copy(with zone: NSZone? = nil) -> Any {
        let copy = MediaConfig(mediaEntry: self.mediaEntry, startTime: self.startTime)
        return copy
    }
}

/// A `PluginConfig` object defines config to use when loading a plugin object.
@objc public class PluginConfig: NSObject {
    /// Plugins config dictionary holds [plugin name : plugin config]
    @objc public var config: [String: Any]
    
    @objc public override var description: String {
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
    
    @objc public func copy(with zone: NSZone? = nil) -> Any {
        let copy = PluginConfig(config: self.config)
        return copy
    }
}




