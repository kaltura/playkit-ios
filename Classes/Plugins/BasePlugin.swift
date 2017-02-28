//
//  BasePlugin.swift
//  Pods
//
//  Created by Gal Orlanczyk on 21/02/2017.
//
//

import Foundation

/// class `BasePlugin` is a base plugin object used for plugin subclasses
@objc public class BasePlugin: NSObject, PKPlugin {
    
    /// abstract implementation subclasses will have names
    public class var pluginName: String {
        fatalError("abstract property should be overriden in subclass")
    }

    public unowned var player: Player
    public unowned var messageBus: MessageBus
    
    public required init(player: Player, pluginConfig: Any?, messageBus: MessageBus) throws {
        PKLog.info("initializing plugin \(type(of:self))")
        self.player = player
        self.messageBus = messageBus
    }
    
    public func onLoad(mediaConfig: MediaConfig) {
        PKLog.info("plugin \(type(of:self)) onLoad with media config: \(mediaConfig)")
    }
    
    public func onUpdateMedia(mediaConfig: MediaConfig) {
        PKLog.info("plugin \(type(of:self)) onUpdateMedia with media config: \(mediaConfig)")
    }
    
    public func destroy() {
        PKLog.info("destroying plugin \(type(of:self))")
    }
}

