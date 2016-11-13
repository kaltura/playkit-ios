//
//  PlayerLoader.swift
//  Pods
//
//  Created by Vadim Kononov on 09/11/2016.
//
//

import Foundation

class PlayerLoader: PlayerDecoratorBase {
    
    var loadedPlugins = [Plugin]()
    
    func load(_ config: PlayerConfig) throws {
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
                                throw PlayKitError.multipleDecoratorsDetected
                            }
                            decorator = d
                            decorator!.setPlayer(player)
                        }
                    }
                    
                    loadedPlugins.append(pluginObject)
                }
            }
        }
        
        if decorator != nil {
            player = decorator!
        }
        
        setPlayer(player)
    }
    
    override func destroy() {
        for plugin in loadedPlugins {
            plugin.destroy()
        }
        super.destroy()
    }
}
