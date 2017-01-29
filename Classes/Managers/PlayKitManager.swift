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

    public static let versionString: String = Bundle.init(for: PlayKitManager.self)
        .object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    
    public static let clientTag = "playkit/ios-\(versionString)"
    
    public static let sharedInstance : PlayKitManager = PlayKitManager()
    
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
    public func loadPlayer(config: PlayerConfig) -> Player {
        let loader = PlayerLoader()
        loader.load(config)
        return loader
    }
    
    public func registerPlugin(_ pluginClass: PKPlugin.Type) {
        pluginRegistry[pluginClass.pluginName] = pluginClass
    }
    
    func createPlugin(name: String) -> PKPlugin? {
        let pluginClass = pluginRegistry[name]
        guard pluginClass != nil else {
            return nil
        }
        return pluginClass?.init()
    }
}
