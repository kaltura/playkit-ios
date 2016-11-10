//
//  PlayerLoader.swift
//  Pods
//
//  Created by Vadim Kononov on 09/11/2016.
//
//

import Foundation

class PlayerLoader: PlayerDecoratorBase {
    
    func load(_ config: PlayerConfig) {
        var player: Player = PlayerController()
        player.prepare(config)
        
        var decorator: PlayerDecoratorBase? = nil
        
        if let plugins = config.plugins {
            for pluginName in plugins.keys {
                if let pluginObject = PlayKitManager.sharedInstance.createPlugin(name: pluginName) {
                    pluginObject.load(player: player, config: plugins[pluginName] as? AnyObject)
                    
                    if pluginObject is DecoratedPlayerProvider {
                        if let d = (pluginObject as! DecoratedPlayerProvider).getDecoratedPlayer() {
                            if decorator != nil {
                                //throw exception
                            }
                            decorator = d
                            decorator!.setPlayer(player)
                        }
                    }
                }
            }
        }
        
        if decorator != nil {
            player = decorator!
        }
        
        setPlayer(player)
    }
}
