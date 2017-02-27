//
//  PlayerLoader.swift
//  Pods
//
//  Created by Vadim Kononov on 09/11/2016.
//
//

import Foundation

class LoadedPlugin: NSObject {
    var plugin: PKPlugin
    var decorator: PlayerDecoratorBase?
    init(plugin :PKPlugin, decorator: PlayerDecoratorBase?) {
        self.plugin = plugin
        self.decorator = decorator
    }
}

class PlayerLoader: PlayerDecoratorBase {
    
    var loadedPlugins = Dictionary<String, LoadedPlugin>()
    var messageBus = MessageBus()
    
    func load(pluginConfig: PluginConfig?) {
        var playerController: PlayerController
        
        playerController = PlayerController()
        playerController.onEventBlock = { [unowned self] event in
            self.messageBus.post(event)
        }
        
        var player: Player = playerController
        
        if let pluginConfigs = pluginConfig?.config {
            for pluginName in pluginConfigs.keys {
                let pluginConfig = pluginConfigs[pluginName]
                do {
                    let pluginObject = try PlayKitManager.shared.createPlugin(name: pluginName, player: player, pluginConfig: pluginConfig, messageBus: self.messageBus)
                    
                    var decorator: PlayerDecoratorBase? = nil
                    
                    if let d = (pluginObject as? PlayerDecoratorProvider)?.getPlayerDecorator() {
                        d.setPlayer(player)
                        decorator = d
                        player = d
                    }
                    
                    loadedPlugins[pluginName] = LoadedPlugin(plugin: pluginObject, decorator: decorator)
                } catch let e {
                    if case PKPluginError.failedToCreatePlugin = e {
                        self.messageBus.post(PlayerEvent.Error(nsError: PKPluginError.failedToCreatePlugin.asNSError))
                    }
                }
            }
        }
        setPlayer(player)
    }
    
    override func prepare(_ config: MediaConfig) {
        super.prepare(config)
        // update all loaded plugins with media config
        for (pluginName, loadedPlugin) in loadedPlugins {
            PKLog.trace("Preparing plugin", pluginName)
            loadedPlugin.plugin.onLoad(mediaConfig: config)
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
    
    public override func addObserver(_ observer: AnyObject, events: [PKEvent.Type], block: @escaping (PKEvent)->Void) {
        // TODO:: finilizing + object validation
        messageBus.addObserver(observer, events: events, block: block)
    }
    
    public override func removeObserver(_ observer: AnyObject, events: [PKEvent.Type]) {
        // TODO:: finilizing + object validation
        messageBus.removeObserver(observer, events: events)
    }
    
}
