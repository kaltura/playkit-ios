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

    private var isFirstPlay = true
    
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
        
        PKLog.trace("Start monitoring using Youbora")

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
        PKLog.trace("Stop monitoring using Youbora")
        youboraManager.stopMonitoring()
    }
    
    private func registerToAllEvents() {
        
        PKLog.trace()
        
        self.messageBus?.addObserver(self, events: [PlayerEvents.canPlay.self], block: { (info) in

            PKLog.trace("canPlay info: \(info)")
            self.youboraManager.joinHandler()
        
        })
        
        self.messageBus?.addObserver(self, events: [PlayerEvents.play.self], block: { (info) in
            
            PKLog.trace("========== play info: \(info)")
            /*
            if self.isFirstPlay {
                self.youboraManager.playHandler()
                self.isFirstPlay = false
            } else {
                self.youboraManager.resumeHandler()
            }*/
            
        })
        
        self.messageBus?.addObserver(self, events: [PlayerEvents.playing.self], block: { (info) in
            PKLog.trace("========== playing info: \(info)")
            //self.youboraManager.pauseHandler()
        })
        
        self.messageBus?.addObserver(self, events: [PlayerEvents.pause.self], block: { (info) in
            PKLog.trace("pause info: \(info)")
            self.youboraManager.pauseHandler()
        })
        
        self.messageBus?.addObserver(self, events: [PlayerEvents.seeking.self], block: { (info) in
            PKLog.trace("seeking info: \(info)")
            self.youboraManager.seekingHandler()
        })
        
        self.messageBus?.addObserver(self, events: [PlayerEvents.seeked.self], block: { (info) in
            PKLog.trace("seeked info: \(info)")
            self.youboraManager.seekedHandler()
        })
        
        self.messageBus?.addObserver(self, events: [PlayerEvents.ended.self], block: { (info) in
            PKLog.trace("ended info: \(info)")
            self.youboraManager.endedHandler()
        })
    }
}







