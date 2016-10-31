//
//  PlayKitManager.swift
//  PlayKit
//
//  Created by Noam Tamim on 31/10/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

import UIKit

public class PlayKitManager: NSObject {

    static var pluginRegistry = Dictionary<String, Plugin.Type>()
    
    public static func createPlayer() -> Player {
        return PlayerImp();
    }
    
    public static func registerPlugin(_ pluginClass: Plugin.Type) {
        pluginRegistry[pluginClass.pluginName] = pluginClass
    }
    
    static func createPlugin(name: String) -> Plugin? {
        let pluginClass = pluginRegistry[name]
        guard pluginClass != nil else {
            return nil
        }
        return pluginClass?.init()
    }
}
