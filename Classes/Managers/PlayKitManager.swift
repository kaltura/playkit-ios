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
public class PlayKitManager: NSObject {

    // private init to prevent initializing this singleton
    private override init() {
        if type(of: self) != PlayKitManager.self {
            fatalError("Private initializer, use shared instance instead")
        }
    }
    
    public static let versionString: String = Bundle(for: PlayKitManager.self)
        .object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    
    public static let clientTag = "playkit/ios-\(versionString)"
    
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
    public func loadPlayer(pluginConfig: PluginConfig?) -> Player {
        let loader = PlayerLoader()
        loader.load(pluginConfig: pluginConfig)
        return loader
    }
    
    public func registerPlugin(_ pluginClass: Plugin.Type) {
        guard let pluginType = pluginClass as? PKPlugin.Type else {
            fatalError("plugin class must be of type PKPlugin")
        }
        pluginRegistry[pluginType.pluginName] = pluginType
    }
    
    func createPlugin(name: String, player: Player, pluginConfig: Any?, messageBus: MessageBus) -> PKPlugin? {
        let pluginClass = pluginRegistry[name]
        guard pluginClass != nil else {
            return nil
        }
        return pluginClass?.init(player: player, pluginConfig: pluginConfig, messageBus: messageBus)
    }
}
