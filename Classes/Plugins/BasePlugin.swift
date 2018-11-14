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

/// class `BasePlugin` is a base plugin object used for plugin subclasses
@objc open class BasePlugin: NSObject, PKPlugin {
    
    /// abstract implementation subclasses will have names
    @objc open class var pluginName: String {
        fatalError("abstract property must be overriden in subclass")
    }
    
    @objc open class var pluginVersion: String {
        guard let version = Bundle(for: self).object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
            return "?.?.?"
        }
        return version
    }

    @objc public weak var player: Player?
    @objc public weak var messageBus: MessageBus?
    
    @objc public required init(player: Player, pluginConfig: Any?, messageBus: MessageBus) throws {
        let pluginClass = type(of: self)
        PKLog.verbose("initializing plugin \(pluginClass)")
        self.player = player
        self.messageBus = messageBus
    }
    
    @objc open func onUpdateMedia(mediaConfig: MediaConfig) {
        PKLog.verbose("plugin \(type(of:self)) onUpdateMedia with media config: \(String(describing: mediaConfig))")
    }
    
    @objc open func onUpdateConfig(pluginConfig: Any) {
        PKLog.verbose("plugin \(type(of:self)) onUpdateConfig with media config: \(String(describing: pluginConfig))")
    }
    
    @objc open func destroy() {
        PKLog.verbose("destroying plugin \(type(of:self))")
    }
}
