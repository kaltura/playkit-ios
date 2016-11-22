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
    var decorator: PlayerDecorator
    init(plugin :PKPlugin, decorator: PlayerDecorator) {
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
            playerController = PlayerController(mediaEntry: mediaEntry)
            
            // TODO::
            // add event listener on player controller
            
            var player: Player = playerController
            var decorator: PlayerDecoratorBase? = nil
            
            if let plugins = config.plugins {
                for pluginName in plugins.keys {
                    if let pluginObject = PlayKitManager.sharedInstance.createPlugin(name: pluginName) {
                        // TODO::
                        // send message bus
                        pluginObject.load(player: player, config: plugins[pluginName] as? AnyObject)
                        
                        if pluginObject is PlayerDecorator {
                            if let d = (pluginObject as! PlayerDecorator).getDecoratedPlayer() {
                                if d != nil {
                                    decorator = d
                                    decorator!.setPlayer(player)
                                }
                            }
                        }

                        loadedPlugins[pluginName] = LoadedPlugin(plugin: pluginObject, decorator: decorator as! PlayerDecorator)
                    }
                    
                    setPlayer(player)
                }
            }
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
                if let decorator = (currentLayer as! PlayerDecorator).getDecoratedPlayer() {
                    currentLayer = decorator
                }
            }
            
            // Release the plugin
            
            loadedPlugin.plugin.destroy()
            loadedPlugins.removeValue(forKey: pluginName)
        }
        
        setPlayer(currentLayer)
    }
    
    override func destroy() {
        self.destroyPlayer()
        self.destroyPlugins()
        super.destroy()
    }
}
