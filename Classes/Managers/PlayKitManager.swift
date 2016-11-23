//
//  PlayKitManager.swift
//  PlayKit
//
//  Created by Noam Tamim on 31/10/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

import UIKit

public class PlayKitManager: NSObject {

    public static let sharedInstance : PlayKitManager = PlayKitManager()
    
    var pluginRegistry = Dictionary<String, PKPlugin.Type>()
    
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
