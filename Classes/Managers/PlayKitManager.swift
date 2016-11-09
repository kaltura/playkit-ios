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
    
    var pluginRegistry = Dictionary<String, Plugin.Type>()
    
    public func createPlayer(config: PlayerConfig) -> Player {
        
        let controller = PlayerController()
        var decorator: Player? = nil
        
        for pluginName in pluginRegistry.keys {
            if let pluginObject = createPlugin(name: pluginName) {
                pluginObject.load(player: controller, config: config)
                
                if pluginObject is DecoratedPlayerProvider {
                    if let d = (pluginObject as! DecoratedPlayerProvider).getDecoratedPlayer() {
                        if decorator != nil {
                            //throw exception
                        }
                        decorator = d
                    }
                }
            }
        }
        
        if decorator != nil {
            return decorator!
        }
        
        return controller
    }
    
    public func registerPlugin(_ pluginClass: Plugin.Type) {
        pluginRegistry[pluginClass.pluginName] = pluginClass
    }
    
    func createPlugin(name: String) -> Plugin? {
        let pluginClass = pluginRegistry[name]
        guard pluginClass != nil else {
            return nil
        }
        return pluginClass?.init()
    }
}
