//
//  YouboraPlugin.swift
//  AdvancedExample
//
//  Created by Oded Klein on 19/10/2016.
//  Copyright © 2016 Kaltura, Inc. All rights reserved.
//

import YouboraLib
import YouboraPluginAVPlayer
import AVFoundation

public class YouboraPlugin: PKPlugin {

    private var player: Player
    private var messageBus: MessageBus
    private var config: AnalyticsConfig?
    private var youboraManager : YouboraManager?
    private var isFirstPlay = true
    
    public static var pluginName: String = "YouboraPlugin"
    public var mediaEntry: MediaEntry?
    
    /************************************************************/
    // MARK: - PKPlugin
    /************************************************************/
    
    public required init(player: Player, pluginConfig: Any?, messageBus: MessageBus) {
        self.player = player
        self.messageBus = messageBus
        if let aConfig = pluginConfig as? AnalyticsConfig {
            self.config = aConfig
        } else {
            PKLog.warning("There is no Analytics Config.")
        }
    }
    
    public func onLoad(mediaConfig: MediaConfig) {
        PKLog.trace("plugin \(type(of:self)) onLoad with media config: \(mediaConfig)")
        self.mediaEntry = mediaConfig.mediaEntry
        self.setupYouboraManager() { succeeded in
            if succeeded {
                self.registerToAllEvents()
                self.startMonitoring(player: self.player)
            }
        }
    }
    
    public func onUpdateMedia(mediaConfig: MediaConfig) {
        PKLog.trace("plugin \(type(of:self)) onLoad with media config: \(mediaConfig)")
        self.mediaEntry = mediaConfig.mediaEntry
        self.setupYouboraManager()
    }
    
    public func destroy() {
        self.stopMonitoring()
    }
    
    /************************************************************/
    // MARK: - Private
    /************************************************************/
    
    private func setupYouboraManager(completionHandler: ((_ succeeded: Bool) -> Void)? = nil) {
        if let config = self.config, var media = config.params["media"] as? [String : Any], let mediaEntry = self.mediaEntry {
            media["resource"] = mediaEntry.id
            media["title"] = mediaEntry.id
            media["duration"] = self.player.duration
            config.params["media"] = media
            youboraManager = YouboraManager(options: config.params as NSObject!, player: player, mediaEntry: mediaEntry)
            completionHandler?(true)
        } else {
            PKLog.warning("There is no config params or MediaEntry, could not setup youbora manager")
            completionHandler?(false)
        }
    }
    
    private func startMonitoring(player: Player) {
        guard let youboraManager = self.youboraManager else { return }
        PKLog.trace("Start monitoring using Youbora")
        youboraManager.startMonitoring(withPlayer: youboraManager)
    }
    
    private func stopMonitoring() {
        guard let youboraManager = self.youboraManager else { return }
        PKLog.trace("Stop monitoring using Youbora")
        youboraManager.stopMonitoring()
    }
    
    private func registerToAllEvents() {
        PKLog.trace("register to all events")
        
        self.messageBus.addObserver(self, events: [PlayerEvent.canPlay], block: { [unowned self] event in
            self.postEventLogWithMessage(message: "canPlay event: \(event)")
        })
        
        self.messageBus.addObserver(self, events: [PlayerEvent.play], block: { [unowned self] event in
            guard let youboraManager = self.youboraManager else { return }
            youboraManager.playHandler()
            self.postEventLogWithMessage(message: "play event: \(event)")
        })
        
        self.messageBus.addObserver(self, events: [PlayerEvent.playing], block: { [unowned self] event in
            self.postEventLogWithMessage(message: "playing event: \(event)")
            
            guard let youboraManager = self.youboraManager else { return }
            if self.isFirstPlay {
                youboraManager.joinHandler()
                youboraManager.bufferedHandler()
                self.isFirstPlay = false
            } else {
                youboraManager.resumeHandler()
            }
        })
        
        self.messageBus.addObserver(self, events: [PlayerEvent.pause], block: { [unowned self] event in
            guard let youboraManager = self.youboraManager else { return }
            youboraManager.pauseHandler()
            self.postEventLogWithMessage(message: "pause event: \(event)")
        })
        
        self.messageBus.addObserver(self, events: [PlayerEvent.seeking], block: { [unowned self] event in
            guard let youboraManager = self.youboraManager else { return }
            youboraManager.seekingHandler()
            self.postEventLogWithMessage(message: "seeking event: \(event)")
        })
        
        self.messageBus.addObserver(self, events: [PlayerEvent.seeked], block: { [unowned self] (event) in
            guard let youboraManager = self.youboraManager else { return }
            youboraManager.seekedHandler()
            self.postEventLogWithMessage(message: "seeked event: \(event)")
        })
        
        self.messageBus.addObserver(self, events: [PlayerEvent.ended], block: { [unowned self] (event) in
            guard let youboraManager = self.youboraManager else { return }
            youboraManager.endedHandler()
            self.postEventLogWithMessage(message: "ended event: \(event)")
        })
        
        self.messageBus.addObserver(self, events: [PlayerEvent.playbackParamsUpdated], block: { [unowned self] (event) in
            guard let youboraManager = self.youboraManager else { return }
            youboraManager.currentBitrate = event.currentBitrate?.doubleValue
            self.postEventLogWithMessage(message: "playbackParamsUpdated event: \(event)")
        })

        self.messageBus.addObserver(self, events: [PlayerEvent.stateChanged]) { [unowned self] (event) in
            guard let youboraManager = self.youboraManager else { return }
            if let stateChanged = event as? PlayerEvent.StateChanged {
                switch event.newState {
                case .buffering:
                    youboraManager.bufferingHandler()
                    self.postEventLogWithMessage(message: "Buffering event: ֿ\(event)")
                    break
                default: break
                }
                
                switch event.oldState {
                case .buffering:
                    youboraManager.bufferedHandler()
                    self.postEventLogWithMessage(message: "Buffered event: \(event)")
                    break
                default: break
                }
            }
        }
        
        self.messageBus.addObserver(self, events: AdEvent.allEventTypes, block: { [unowned self] (event) in
            self.postEventLogWithMessage(message: "Ads event event: \(event)")
        })
    }
    
    private func postEventLogWithMessage(message: String) {
        PKLog.trace(message)
        let eventLog = YouboraEvent.YouboraReportSent(message: message as NSString)
        self.messageBus.post(eventLog)
    }
}

