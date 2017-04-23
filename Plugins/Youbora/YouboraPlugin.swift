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

public class YouboraPlugin: BaseAnalyticsPlugin, AppStateObservable {
    
    public override class var pluginName: String {
        return "YouboraPlugin"
    }
    
    private var youboraManager: YouboraManager
    /// Smart Ads plugin, `YouboraAdnalyzerManager` inherits from `YBAdnalyzerGeneric`
    /// Will only be used when configured enableAdnalyzer == true.
    private var adnalyzerManager: YouboraAdnalyzerManager?
    
    /************************************************************/
    // MARK: - PKPlugin
    /************************************************************/
    
    public required init(player: Player, pluginConfig: Any?, messageBus: MessageBus) throws {
        guard let config = pluginConfig as? AnalyticsConfig else {
            PKLog.error("missing plugin config")
            throw PKPluginError.missingPluginConfig(pluginName: YouboraPlugin.pluginName)
        }
        /// initialize youbora manager
        let options = config.params
        let optionsObject = NSDictionary(dictionary: options)
        self.youboraManager = YouboraManager(options: optionsObject, player: player)
        
        try super.init(player: player, pluginConfig: pluginConfig, messageBus: messageBus)
        
        // if adnalyzer is enabled initialize it only once when youbora manager is initialized
        if let enableAdnalyzer = self.config?.params["enableAdnalyzer"] as? Bool, enableAdnalyzer == true {
            self.adnalyzerManager = YouboraAdnalyzerManager(pluginInstance: self.youboraManager)
        }
        // start monitoring for events
        self.startMonitoring()
        
        AppStateSubject.shared.add(observer: self)
    }
    
    public override func onUpdateMedia(mediaConfig: MediaConfig) {
        // play handler to start when asset starts loading.
        // this point is the closest point to prepare call.
        self.youboraManager.playHandler()
        
        super.onUpdateMedia(mediaConfig: mediaConfig)
        self.setupYoubora()
    }
    
    public override func onUpdateConfig(pluginConfig: Any) {
        super.onUpdateConfig(pluginConfig: pluginConfig)
        self.setupYoubora()
    }
    
    public override func destroy() {
        self.stopMonitoring()
        super.destroy()
    }
    
    /************************************************************/
    // MARK: - AnalytisPluginProtocol
    /************************************************************/
    
    override var playerEventsToRegister: [PlayerEvent.Type] {
        return [
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
            case let e where e.self == PlayerEvent.pause:
                self.messageBus?.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    strongSelf.youboraManager.pauseHandler()
                    strongSelf.postEventLogWithMessage(message: "\(type(of: event))")
                }
            case let e where e.self == PlayerEvent.playing:
                self.messageBus?.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    strongSelf.postEventLogWithMessage(message: "\(String(describing: type(of: event)))")
                    if strongSelf.isFirstPlay {
                        strongSelf.isFirstPlay = false
                        strongSelf.youboraManager.joinHandler()
                        strongSelf.youboraManager.bufferedHandler()
                    } else {
                        strongSelf.youboraManager.resumeHandler()
                    }
                }
            case let e where e.self == PlayerEvent.seeking:
                self.messageBus?.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    strongSelf.youboraManager.seekingHandler()
                    strongSelf.postEventLogWithMessage(message: "\(type(of: event))")
                }
            case let e where e.self == PlayerEvent.seeked:
                self.messageBus?.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    strongSelf.youboraManager.seekedHandler()
                    strongSelf.postEventLogWithMessage(message: "\(type(of: event))")
                }
            case let e where e.self == PlayerEvent.ended:
                self.messageBus?.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    strongSelf.youboraManager.endedHandler()
                    strongSelf.postEventLogWithMessage(message: "\(type(of: event))")
                }
            case let e where e.self == PlayerEvent.playbackParamsUpdated:
                self.messageBus?.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    strongSelf.youboraManager.currentBitrate = event.currentBitrate?.doubleValue
                    strongSelf.postEventLogWithMessage(message: "\(type(of: event))")
                }
            case let e where e.self == PlayerEvent.stateChanged:
                self.messageBus?.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    if event.newState == .buffering {
                        strongSelf.youboraManager.bufferingHandler()
                        strongSelf.postEventLogWithMessage(message: "\(type(of: event))")
                    } else if event.oldState == .buffering {
                        strongSelf.youboraManager.bufferedHandler()
                        strongSelf.postEventLogWithMessage(message: "\(type(of: event))")
                    }
                }
            default: assertionFailure("all events must be handled")
            }
        }
    }
    
    /************************************************************/
    // MARK: - App State Handling
    /************************************************************/
    
    var observations: Set<NotificationObservation> {
        return [
            NotificationObservation(name: .UIApplicationWillTerminate) { [unowned self] in
                PKLog.debug("youbora plugin will terminate event received, sending analytics pause event")
                self.youboraManager.pauseHandler()
                AppStateSubject.shared.remove(observer: self)
            }
        ]
    }
    
    /************************************************************/
    // MARK: - Private
    /************************************************************/
    
    private func setupYoubora() {
        guard let player = self.player else { return }
        guard let mediaEntry = player.mediaEntry else {
            PKLog.error("missing MediaEntry, could not setup youbora manager")
            self.messageBus?.post(PlayerEvent.PluginError(nsError: YouboraPluginError.failedToSetupYouboraManager.asNSError))
            return
        }
        
        guard let config = self.config else {
            PKLog.error("config params doesn't exist, could not setup youbora manager")
            self.messageBus?.post(PlayerEvent.PluginError(nsError: YouboraPluginError.failedToSetupYouboraManager.asNSError))
            return
        }
        
        var options = config.params
        
        // if media exists overwrite using the new info, else create a new media dictionary
        if var media = options["media"] as? [String: Any] {
            media["resource"] = mediaEntry.id
            media["title"] = mediaEntry.id
            media["duration"] = player.duration
            options["media"] = media
        } else {
            options["media"] = [
                "resource" : mediaEntry.id,
                "title" : mediaEntry.id,
                "duration" : mediaEntry.duration
            ]
        }
        
        let optionsObject = NSDictionary(dictionary: options)
        
        // if youbora manager already created just update options
        self.youboraManager.setOptions(optionsObject)
    }
    
    private func startMonitoring() {
        PKLog.debug("Start monitoring Youbora")
        youboraManager.startMonitoring(withPlayer: nil)
        if let adnalyzerManager = self.adnalyzerManager {
            PKLog.debug("Start monitoring Youbora Adnalyzer")
            // we start monitoring using messageBus object because he is the one handling our events not the player
            adnalyzerManager.startMonitoring(withPlayer: self.messageBus)
        }
    }
    
    private func stopMonitoring() {
        PKLog.debug("Stop monitoring using Youbora")
        youboraManager.stopMonitoring()
        if let adnalyzerManager = self.adnalyzerManager {
            PKLog.debug("Stop monitoring using Youbora")
            adnalyzerManager.stopMonitoring()
        }
    }
    
    private func postEventLogWithMessage(message: String) {
        let eventLog = YouboraEvent.Report(message: message)
        self.messageBus?.post(eventLog)
    }
}
