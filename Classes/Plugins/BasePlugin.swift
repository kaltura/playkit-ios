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
        fatalError("abstract property should be overriden in subclass")
    }

    @objc public weak var player: Player?
    @objc public weak var messageBus: MessageBus?
    
    @objc public required init(player: Player, pluginConfig: Any?, messageBus: MessageBus) throws {
        let pluginClass = type(of: self)
        PKLog.trace("initializing plugin \(pluginClass)")
        self.player = player
        self.messageBus = messageBus
    }
    
    @objc open func onUpdateMedia(mediaConfig: MediaConfig) {
        PKLog.trace("plugin \(type(of:self)) onUpdateMedia with media config: \(String(describing: mediaConfig))")
    }
    
    @objc open func onUpdateConfig(pluginConfig: Any) {
        PKLog.trace("plugin \(type(of:self)) onUpdateConfig with media config: \(String(describing: pluginConfig))")
    }
    
    @objc open func destroy() {
        PKLog.trace("destroying plugin \(type(of:self))")
    }
}
