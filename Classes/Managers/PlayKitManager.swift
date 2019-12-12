// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import UIKit
import PlayKitUtils

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
    
    
    public static let userAgent = UserAgent.build(clientTag: clientTag)
    
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
    /// - Parameter pluginConfig: The configuration object to load the player with.
    /// - Returns: A player loaded using the provided configuration.
    @objc public func loadPlayer(pluginConfig: PluginConfig?) -> Player {
        let loader = PlayerLoader()
        loader.load(pluginConfig: pluginConfig)
        return loader
    }
    
    @objc public func registerPlugin(_ pluginClass: BasePlugin.Type) {
        
        PKLog.info("Registering plugin \(pluginClass.pluginName)/\(pluginClass.pluginVersion)")
        
        if let pluginWarmUp = pluginClass as? PKPluginWarmUp.Type {
            pluginWarmUp.warmUp()
        }
        pluginRegistry[pluginClass.pluginName] = pluginClass
    }
    
    @objc public func registeredPlugins() -> [String: String] {
        var dict = [String: String]()
        for (name, type) in pluginRegistry {
            dict[name] = type.pluginVersion
        }
        return dict
    }
    
    func createPlugin(name: String, player: Player, pluginConfig: Any?, messageBus: MessageBus) throws -> PKPlugin {
        guard let pluginClass = pluginRegistry[name] else {
            PKLog.error("plugin with name: \(name) doesn't exist in pluginRegistry")
            throw PKPluginError.failedToCreatePlugin(pluginName: name).asNSError
        }
        return try pluginClass.init(player: player, pluginConfig: pluginConfig, messageBus: messageBus)
    }
    
    /// sets the logging level for our logger.
    @objc public static var logLevel: PKLogLevel = .default {
        didSet {
            PKLog.outputLevel = logLevel.toLoggerLevel
        }
    }
}
