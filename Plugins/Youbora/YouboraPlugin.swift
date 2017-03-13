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

/************************************************************/
// MARK: - YouboraPluginError
/************************************************************/

/// `YouboraPluginError` represents youbora plugin errors.
enum YouboraPluginError: PKError {
    
    case failedToSetupYouboraManager
    
    static let domain = "com.kaltura.playkit.error.youbora"
    
    var code: Int {
        switch self {
        case .failedToSetupYouboraManager: return PKErrorCode.failedToSetupYouboraManager
        }
    }
    
    var errorDescription: String {
        switch self {
        case .failedToSetupYouboraManager: return "failed to setup youbora manager, missing config/config params or mediaEntry"
        }
    }
    
    var userInfo: [String: Any] {
        switch self {
        case .failedToSetupYouboraManager: return [:]
        }
    }
}

extension PKErrorDomain {
    @objc(Youbora) public static let youbora = YouboraPluginError.domain
}

extension PKErrorCode {
    @objc(FailedToSetupYouboraManager) public static let failedToSetupYouboraManager = 2200
}

/************************************************************/
// MARK: - YouboraPlugin
/************************************************************/

public class YouboraPlugin: BaseAnalyticsPlugin {
    
    public override class var pluginName: String {
        return "YouboraPlugin"
    }
    
    private var youboraManager : YouboraManager?
    
    /************************************************************/
    // MARK: - PKPlugin
    /************************************************************/
    
    public required init(player: Player, pluginConfig: Any?, messageBus: MessageBus) throws {
        try super.init(player: player, pluginConfig: pluginConfig, messageBus: messageBus)
        guard let _ = pluginConfig as? AnalyticsConfig else {
            PKLog.error("missing plugin config")
            throw PKPluginError.missingPluginConfig(pluginName: YouboraPlugin.pluginName)
        }
    }
    
    public override func onLoad(mediaConfig: MediaConfig) {
        super.onLoad(mediaConfig: mediaConfig)
        self.setupYouboraManager() { succeeded in
            if succeeded {
                self.startMonitoring(player: self.player)
            }
        }
    }
    
    public override func onUpdateMedia(mediaConfig: MediaConfig) {
        super.onUpdateMedia(mediaConfig: mediaConfig)
        self.setupYouboraManager()
    }
    
    public override func destroy() {
        super.destroy()
        self.stopMonitoring()
    }
    
    /************************************************************/
    // MARK: - AnalytisPluginProtocol
    /************************************************************/
    
    override var playerEventsToRegister: [PlayerEvent.Type] {
        return [
            PlayerEvent.canPlay,
            PlayerEvent.play,
            PlayerEvent.pause,
            PlayerEvent.playing,
            PlayerEvent.seeking,
            PlayerEvent.seeked,
            PlayerEvent.ended,
            PlayerEvent.playbackParamsUpdated,
            PlayerEvent.stateChanged
        ]
    }
    
    override func registerEvents() {
        PKLog.debug("register player events")
        
        self.playerEventsToRegister.forEach { event in
            PKLog.debug("Register event: \(event.self)")
            
            switch event {
            case let e where e.self == PlayerEvent.canPlay:
                self.messageBus.addObserver(self, events: [e.self]) { [unowned self] event in
                    self.postEventLogWithMessage(message: "canPlay event: \(event)")
                }
            case let e where e.self == PlayerEvent.play:
                self.messageBus.addObserver(self, events: [e.self]) { [unowned self] event in
                    guard let youboraManager = self.youboraManager else { return }
                    youboraManager.playHandler()
                    self.postEventLogWithMessage(message: "play event: \(event)")
                }
            case let e where e.self == PlayerEvent.pause:
                self.messageBus.addObserver(self, events: [e.self]) { [unowned self] event in
                    guard let youboraManager = self.youboraManager else { return }
                    youboraManager.pauseHandler()
                    self.postEventLogWithMessage(message: "pause event: \(event)")
                }
            case let e where e.self == PlayerEvent.playing:
                self.messageBus.addObserver(self, events: [e.self]) { [unowned self] event in
                    self.postEventLogWithMessage(message: "playing event: \(event)")
                    
                    guard let youboraManager = self.youboraManager else { return }
                    
                    if self.isFirstPlay {
                        youboraManager.joinHandler()
                        youboraManager.bufferedHandler()
                        self.isFirstPlay = false
                    } else {
                        youboraManager.resumeHandler()
                    }
                }
            case let e where e.self == PlayerEvent.seeking:
                self.messageBus.addObserver(self, events: [e.self]) { [unowned self] event in
                    guard let youboraManager = self.youboraManager else { return }
                    youboraManager.seekingHandler()
                    self.postEventLogWithMessage(message: "seeking event: \(event)")
                }
            case let e where e.self == PlayerEvent.seeked:
                self.messageBus.addObserver(self, events: [e.self]) { [unowned self] (event) in
                    guard let youboraManager = self.youboraManager else { return }
                    youboraManager.seekedHandler()
                    self.postEventLogWithMessage(message: "seeked event: \(event)")
                }
            case let e where e.self == PlayerEvent.ended:
                self.messageBus.addObserver(self, events: [e.self]) { [unowned self] (event) in
                    guard let youboraManager = self.youboraManager else { return }
                    youboraManager.endedHandler()
                    self.postEventLogWithMessage(message: "ended event: \(event)")
                }
            case let e where e.self == PlayerEvent.playbackParamsUpdated:
                self.messageBus.addObserver(self, events: [e.self]) { [unowned self] (event) in
                    guard let youboraManager = self.youboraManager else { return }
                    youboraManager.currentBitrate = event.currentBitrate?.doubleValue
                    self.postEventLogWithMessage(message: "playbackParamsUpdated event: \(event)")
                }
            case let e where e.self == PlayerEvent.stateChanged:
                self.messageBus.addObserver(self, events: [e.self]) { [unowned self] (event) in
                    guard let youboraManager = self.youboraManager else { return }
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
            default: assertionFailure("all events must be handled")
            }
        }
        
        PKLog.debug("register ads events")
        self.messageBus.addObserver(self, events: AdEvent.allEventTypes) { [unowned self] (event) in
            self.postEventLogWithMessage(message: "Ads event event: \(event)")
        }
    }
    
    /************************************************************/
    // MARK: - Private
    /************************************************************/
    
    private func setupYouboraManager(completionHandler: ((_ succeeded: Bool) -> Void)? = nil) {
        
        guard let mediaEntry = self.player.mediaEntry else {
            PKLog.error("missing MediaEntry, could not setup youbora manager")
            self.messageBus.post(PlayerEvent.PluginError(nsError: YouboraPluginError.failedToSetupYouboraManager.asNSError))
            completionHandler?(false)
            return
        }
        
        guard let config = self.config else {
            PKLog.error("config params doesn't exist, could not setup youbora manager")
            self.messageBus.post(PlayerEvent.PluginError(nsError: YouboraPluginError.failedToSetupYouboraManager.asNSError))
            completionHandler?(false)
            return
        }
        
        var options = [String: Any]()
        
        // if media exists overwrite using the new info, else create a new media dictionary
        if var media = config.params["media"] as? [String: Any] {
            media["resource"] = mediaEntry.id
            media["title"] = mediaEntry.id
            media["duration"] = self.player.duration
            config.params["media"] = media
        } else {
            config.params["media"] = [
                "resource" : mediaEntry.id,
                "title" : mediaEntry.id,
                "duration" : mediaEntry.duration
            ]
        }
        options = config.params
        
        // if youbora manager already created just update options
        if let youboraManager = self.youboraManager {
            youboraManager.setOptions(options as NSObject!)
        } else {
            self.youboraManager = YouboraManager(options: options as NSObject!, player: player, mediaEntry: mediaEntry)
        }
        completionHandler?(true)
    }
    
    private func startMonitoring(player: Player) {
        guard let youboraManager = self.youboraManager else { return }
        PKLog.debug("Start monitoring using Youbora")
        youboraManager.startMonitoring(withPlayer: youboraManager)
    }
    
    private func stopMonitoring() {
        guard let youboraManager = self.youboraManager else { return }
        PKLog.debug("Stop monitoring using Youbora")
        youboraManager.stopMonitoring()
    }
    
    private func postEventLogWithMessage(message: String) {
        PKLog.debug(message)
        let eventLog = YouboraEvent.YouboraReportSent(message: message as NSString)
        self.messageBus.post(eventLog)
    }
}

