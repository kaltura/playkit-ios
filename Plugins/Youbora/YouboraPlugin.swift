//
//  YouboraPlugin.swift
//  AdvancedExample
//
//  Created by Oded Klein on 19/10/2016.
//  Copyright © 2016 Google, Inc. All rights reserved.
//

import YouboraLib
import YouboraPluginAVPlayer

public class YouboraPlugin : PKPlugin {

    private var player: Player!
    private var messageBus: MessageBus?
    private var config: AnalyticsConfig!
    
    private var youboraManager : YBPluginAVPlayer!
    public static var pluginName: String = "YouboraPlugin"

    required public init() {

    }
    
    public func load(player: Player, config: Any?, messageBus: MessageBus) {
    
        self.messageBus = messageBus
        
        if let aConfig = config as? AnalyticsConfig {
            self.config = aConfig
            self.player = player
        }
        
        let options = [String : Any]()
        youboraManager = YBPluginAVPlayer(options: options as NSObject!)
        
        registerToAllEvents()
        
        startMonitoring(player: player)
    }
    
    public func destroy() {
        stopMonitoring()
    }
    
    private func startMonitoring(player: Player) {
        var yConfig = YouboraConfig.defaultYouboraConfig
        var media : [String: Any] = yConfig["media"] as! [String : Any]
        
        if let entry = self.config.mediaEntry {
            media["resource"] = entry.id
            media["title"] = entry.id
            media["duration"] = entry.duration
            
            youboraManager.setOptions(yConfig as NSObject!)
            youboraManager.startMonitoring(withPlayer: player as! NSObject)
        }

    }
    
    private func stopMonitoring() {
        youboraManager.stopMonitoring()
    }
    
    private func registerToAllEvents() {
        
        self.messageBus?.addObserver(self, event: PlayerEvents.play, block: { (info) in
            
            print("Play: \(info)")
            //self.youboraManager.playHandler()
            
        })
        
        self.messageBus?.addObserver(self, event: PlayerEvents.pause, block: { (info) in
            print("Pause: \(info)")
        })
        
        self.messageBus?.addObserver(self, event: PlayerEvents.canPlay, block: { (info) in
            print("CanPlay: \(info)")
        })
    }
}

