//
//  PlayKitManager.swift
//  PlayKit
//
//  Created by Noam Tamim on 31/10/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

import UIKit

/**
 Manager class used for:
  - creating `Player` objects.
  - creating and registering plugins.
 */
@objc public class PlayKitManager: NSObject {

    // private init to prevent initializing this singleton
    private override init() {
        if type(of: self) != PlayKitManager.self {
            fatalError("Private initializer, use shared instance instead")
        }
    }
    
    @objc public static let versionString: String = Bundle(for: PlayKitManager.self).object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    
    @objc public static let clientTag = "playkit/ios-\(versionString)"
    
    @objc(sharedInstance) public static let shared: PlayKitManager = PlayKitManager()
    
    var pluginRegistry = Dictionary<String, PKPlugin.Type>()
    
    /// Loads and returns a player object using a provided configuration.
    ///
    /// - Important: In order to start buffering the video after loading the player
    /// you must call prepare on the player with the same configuration.
    /// ````
    ///     player = PlayKitManager.sharedInstance.loadPlayer(config: config)
    ///     player.prepare(config)
    /// ````
    ///
    /// - Parameter config: The configuration object to load the player with.
    /// - Returns: A player loaded using the provided configuration.
    @objc public func loadPlayer(pluginConfig: PluginConfig?) throws -> Player {
        let loader = PlayerLoader()
        try loader.load(pluginConfig: pluginConfig)
        return loader
    }
    
    @objc public func registerPlugin(_ pluginClass: BasePlugin.Type) {
        pluginRegistry[pluginClass.pluginName] = pluginClass
    }
    
    func createPlugin(name: String, player: Player, pluginConfig: Any?, messageBus: MessageBus) throws -> PKPlugin {
        guard let pluginClass = pluginRegistry[name] else {
            PKLog.error("plugin with name: \(name) doesn't exist in pluginRegistry")
            throw PKPluginError.failedToCreatePlugin(pluginName: name).asNSError
        }
        return try pluginClass.init(player: player, pluginConfig: pluginConfig, messageBus: messageBus)
    }
}
