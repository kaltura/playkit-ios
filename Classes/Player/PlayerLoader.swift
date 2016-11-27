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
            playerController.registerEventChange({ (event:PKEvent) in
                self.messageBus.post(event)
            })
            
            // TODO::
            // add event listener on player controller
            
            var player: Player = playerController
            
            if let plugins = config.plugins {
                for pluginName in plugins.keys {
                    if let pluginObject = PlayKitManager.sharedInstance.createPlugin(name: pluginName) {
                        // TODO::
                        // send message bus
                        var decorator: PlayerDecoratorBase? = nil
                        
                        pluginObject.load(player: player, config: plugins[pluginName], messageBus: self.messageBus)
                        
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
    
    public func addObserver(_ observer: AnyObject, events: [PKEvent.Type], block: @escaping (_ info: Any)->Void) {
        // TODO:: finilizing + object validation
        messageBus.addObserver(observer, events: events, block: block)
    }
    
    public func removeObserver(_ observer: AnyObject, events: [PKEvent.Type]) {
        // TODO:: finilizing + object validation
        messageBus.removeObserver(observer, events: events)
    }
}
