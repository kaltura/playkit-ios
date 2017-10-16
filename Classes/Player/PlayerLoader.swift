// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import Foundation

class LoadedPlugin: NSObject {
    var plugin: PKPlugin
    var decorator: PlayerDecoratorBase?
    init(plugin: PKPlugin, decorator: PlayerDecoratorBase?) {
        self.plugin = plugin
        self.decorator = decorator
    }
}

class PlayerLoader: PlayerDecoratorBase {
    
    var loadedPlugins = Dictionary<String, LoadedPlugin>()
    var messageBus = MessageBus()
    var concreatePlayerController: PlayerController?
    
    func load(pluginConfig: PluginConfig?) throws {
        var playerController: PlayerController
        
        playerController = PlayerController()
        playerController.onEventBlock = { [weak self] event in
            self?.messageBus.post(event)
        }
        
        self.concreatePlayerController = playerController
        var player: Player = playerController
        
        // initial creation of play session id adapter will update session id in prepare if needed
        player.settings.contentRequestAdapter = KalturaPlaybackRequestAdapter()
        
        if let pluginConfigs = pluginConfig?.config {
            for pluginName in pluginConfigs.keys {
                let pluginConfig = pluginConfigs[pluginName]
                let pluginObject = try PlayKitManager.shared.createPlugin(name: pluginName, player: player, pluginConfig: pluginConfig, messageBus: self.messageBus)
                
                var decorator: PlayerDecoratorBase? = nil
                
                if let d = (pluginObject as? PlayerDecoratorProvider)?.getPlayerDecorator() {
                    d.setPlayer(player)
                    decorator = d
                    player = d
                }
                
                loadedPlugins[pluginName] = LoadedPlugin(plugin: pluginObject, decorator: decorator)
            }
        }
        
        setPlayer(player)
    }
    
    override func prepare(_ config: MediaConfig) {
        self.concreatePlayerController?.setMedia(from: config)
        super.prepare(config)
        // update all loaded plugins with media config
        for (pluginName, loadedPlugin) in loadedPlugins {
            PKLog.trace("Preparing plugin", pluginName)
            loadedPlugin.plugin.onUpdateMedia(mediaConfig: config)
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
    
    public override func addObserver(_ observer: AnyObject, event: PKEvent.Type, block: @escaping (PKEvent) -> Void) {
        messageBus.addObserver(observer, events: [event], block: block)
    }
    
    public override func addObserver(_ observer: AnyObject, events: [PKEvent.Type], block: @escaping (PKEvent)->Void) {
        messageBus.addObserver(observer, events: events, block: block)
    }
    
    override func removeObserver(_ observer: AnyObject, event: PKEvent.Type) {
        messageBus.removeObserver(observer, events: [event])
    }
    
    public override func removeObserver(_ observer: AnyObject, events: [PKEvent.Type]) {
        messageBus.removeObserver(observer, events: events)
    }
    
    public override func updatePluginConfig(pluginName: String, config: Any) {
        guard let loadedPlugin: LoadedPlugin = loadedPlugins[pluginName] else {
            PKLog.debug("There is no such plugin: \(pluginName)");
            return
        }
        
        loadedPlugin.plugin.onUpdateConfig(pluginConfig: config)
    }
    
}
