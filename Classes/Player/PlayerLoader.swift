//
//  PlayerLoader.swift
//  Pods
//
//  Created by Vadim Kononov on 09/11/2016.
//
//

import Foundation

class LoadedPlugin {
    var plugin: PKPlugin
    var decorator: PlayerDecoratorBase?
    init(plugin :PKPlugin, decorator: PlayerDecoratorBase?) {
        self.plugin = plugin
        self.decorator = decorator
    }
}

class PlayerLoader: PlayerDecoratorBase {
    
    // var loadedPlugins = [PKPlugin]()
    var loadedPlugins = Dictionary<String, LoadedPlugin>()
    var messageBus = MessageBus()
    
    func load(_ config: PlayerConfig) {
        var playerController: PlayerController
        
        if let mediaEntry = config.mediaEntry {
            playerController = PlayerController(mediaEntry: config)
            
            // TODO::
            // add event listener on player controller
            
            var player: Player = playerController
            
            if let plugins = config.plugins {
                for pluginName in plugins.keys {
                    if let pluginObject = PlayKitManager.sharedInstance.createPlugin(name: pluginName) {
                        // TODO::
                        // send message bus
                        var decorator: PlayerDecoratorBase? = nil
                        
                        pluginObject.load(player: player, config: plugins[pluginName], messageBus: messageBus)
                        
                        if let d = (pluginObject as? PlayerDecoratorProvider)?.getPlayerDecorator() {
                            d.setPlayer(player)
                            decorator = d
                            player = d
                        }
                        
                        loadedPlugins[pluginName] = LoadedPlugin(plugin: pluginObject, decorator: decorator)
                    }
                }
            }
            setPlayer(player)
            playerController.prepare(config)
        }
    }
    
    func destroyPlayer() {
        getPlayer().destroy()
    }
    
    func destroyPlugins() {
        var currentLayer = getPlayer()
        
        for (pluginName, loadedPlugin) in self.loadedPlugins.reversed() {
            // Peel off decorator, if this plugin added one
            if loadedPlugin.decorator != nil {
                //TODO:: assert
                if let layer = currentLayer as? PlayerDecoratorBase {
                    currentLayer = layer.getPlayer()
                }
            }
            
            // Release the plugin
            loadedPlugin.plugin.destroy()
            loadedPlugins.removeValue(forKey: pluginName)
        }
        
        setPlayer(currentLayer)
    }
    
    override func destroy() {
        self.destroyPlugins()
        self.destroyPlayer()
    }
}
