//
//  YouboraPlugin.swift
//  AdvancedExample
//
//  Created by Oded Klein on 19/10/2016.
//  Copyright © 2016 Google, Inc. All rights reserved.
//

import YouboraLib
import YouboraPluginAVPlayer
import AVFoundation

public class YouboraPlugin: PKPlugin {

    private var player: Player!
    private var messageBus: MessageBus?
    private var config: AnalyticsConfig!
    private var mediaEntry: MediaEntry!
    
    private var youboraManager : YouboraManager!
    public static var pluginName: String = "YouboraPlugin"

    private var isFirstPlay = true
    
    required public init() {

    }
    
    public func load(player: Player, mediaConfig: MediaEntry, pluginConfig: Any?, messageBus: MessageBus) {
    
        self.messageBus = messageBus
        self.mediaEntry = mediaConfig
        
        if let aConfig = pluginConfig as? AnalyticsConfig {
            self.config = aConfig
            self.player = player
        } else {
            PKLog.warning("There is no Analytics Config.")
        }
        
        setupOptions()
        
        registerToAllEvents()
        
        startMonitoring(player: player)
    }
    
    public func destroy() {
        stopMonitoring()
    }
    
    private func setupOptions() {
        let options = self.config.params
        if var media = options?["media"] as? [String: Any] {
            if let entry = self.mediaEntry {
                media["resource"] = entry.id
                media["title"] = entry.id
                media["duration"] = self.player.duration
                
            } else {
                PKLog.warning("There is no MediaEntry")
            }
        }
        youboraManager = YouboraManager(options: options as NSObject!, player: player, media: self.mediaEntry)
	
    }
    
    private func startMonitoring(player: Player) {
        PKLog.trace("Start monitoring using Youbora")
        youboraManager.startMonitoring(withPlayer: youboraManager)
    }
    
    private func stopMonitoring() {
        PKLog.trace("Stop monitoring using Youbora")
        youboraManager.stopMonitoring()
    }
    
    private func registerToAllEvents() {
        
        PKLog.trace()
        
        self.messageBus?.addObserver(self, events: [PlayerEvents.canPlay.self], block: { (info) in
            PKLog.trace("canPlay info: \(info)")
            
            self.postEventLogWithMessage(message: "Event info: \(info)")
        })
        
        self.messageBus?.addObserver(self, events: [PlayerEvents.play.self], block: { (info) in
            PKLog.trace("play info: \(info)")
            self.youboraManager.playHandler()
            self.postEventLogWithMessage(message: "Event info: \(info)")
        })
        
        self.messageBus?.addObserver(self, events: [PlayerEvents.playing.self], block: { (info) in
            PKLog.trace("playing info: \(info)")
            self.postEventLogWithMessage(message: "Event info: \(info)")

            if self.isFirstPlay {

                //let timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(YouboraPlugin.didStartPlaying), userInfo: nil, repeats: false)
                //timer.fire()

                self.youboraManager.joinHandler()
                self.youboraManager.bufferedHandler()
                self.isFirstPlay = false
            } else {
                self.youboraManager.resumeHandler()
            }
        })
        
        self.messageBus?.addObserver(self, events: [PlayerEvents.pause.self], block: { (info) in
            PKLog.trace("pause info: \(info)")
            self.youboraManager.pauseHandler()
            self.postEventLogWithMessage(message: "Event info: \(info)")
        })
        
        self.messageBus?.addObserver(self, events: [PlayerEvents.seeking.self], block: { (info) in
            PKLog.trace("seeking info: \(info)")
            self.youboraManager.seekingHandler()
            
            self.postEventLogWithMessage(message: "Event info: \(info)")
        })
        
        self.messageBus?.addObserver(self, events: [PlayerEvents.seeked.self], block: { (info) in
            PKLog.trace("seeked info: \(info)")
            self.youboraManager.seekedHandler()
            
            self.postEventLogWithMessage(message: "Event info: \(info)")
        })
        
        self.messageBus?.addObserver(self, events: [PlayerEvents.ended.self], block: { (info) in
            PKLog.trace("ended info: \(info)")
            self.youboraManager.endedHandler()
            
            self.postEventLogWithMessage(message: "Event info: \(info)")
        })
        
        self.messageBus?.addObserver(self, events: [PlayerEvents.playbackParamsUpdated.self], block: { (info) in
            PKLog.trace("playbackParamsUpdated info: \(info)")
            if let paramsEvent = info as? PlayerEvents.playbackParamsUpdated {
                self.youboraManager.currentBitrate = paramsEvent.currentBitrate
            }
            self.postEventLogWithMessage(message: "Event info: \(info)")
        })

        self.player.addObserver(self, events: [PlayerEvents.stateChanged.self]) { (data: Any) in
            
            if let stateChanged = data as? PlayerEvents.stateChanged {

                switch stateChanged.newState {
                case .buffering:
                    self.youboraManager.bufferingHandler()
                    self.postEventLogWithMessage(message: "Event info: Buffering")
                    break
                default:
                    
                    break
                }
                
                switch stateChanged.oldState {
                case .buffering:
                    self.youboraManager.bufferedHandler()
                    self.postEventLogWithMessage(message: "Event info: Buffered")
                    break
                default:
                    
                    break
                }
            }
            
            
        }
        
        self.messageBus?.addObserver(self, events: AdEvents.allEventTypes, block: { (info) in
            
            PKLog.trace("Ads event info: \(info)")

            self.postEventLogWithMessage(message: "Event info: \(info)")
        })
    }
    
    private func postEventLogWithMessage(message: String) {
        let eventLog = YouboraReportSent(message: message)
        self.messageBus?.post(eventLog)
    }
    
    @objc private func didStartPlaying() {
        PKLog.trace("didStartPlaying")
        self.youboraManager.joinHandler()
    }
}







