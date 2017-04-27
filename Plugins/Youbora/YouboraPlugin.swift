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
// MARK: - YouboraPlugin
/************************************************************/

public class YouboraPlugin: BaseAnalyticsPlugin, AppStateObservable {
    
    public override class var pluginName: String {
        return "YouboraPlugin"
    }
    
    /// The youbora plugin inheriting from `YBPluginGeneric`
    /// - important: Make sure to call `playHandler()` at the start of any flow before everying
    /// (for example before pre-roll in ads) also make sure to call `endedHandler() at the end of every flow
    /// (for example when we have post-roll call it after the ad).
    /// In addition, when content ends in the middle also make sure to call `endedHandler()`
    /// otherwise youbora will wait for /stop event and you could not start new content events until /stop is received.
    private var youboraManager: YouboraManager
    private var adnalyerManager: YouboraAdnalyzerManager
    
    /// Indicates if we have to delay the endedHandler() (for example when we have post-roll).
    private var shouldDelayEndedHandler = false
    
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
        self.adnalyerManager = YouboraAdnalyzerManager(pluginInstance: self.youboraManager)
        
        try super.init(player: player, pluginConfig: pluginConfig, messageBus: messageBus)
        
        // start monitoring for events
        self.startMonitoring()
        // monitor app state changes
        AppStateSubject.shared.add(observer: self)
        
        self.setupYoubora(withConfig: config)
    }
    
    public override func onUpdateMedia(mediaConfig: MediaConfig) {
        super.onUpdateMedia(mediaConfig: mediaConfig)
        // in case we stopped playback in the middle call eneded handlers and reset state.
        self.endedHandler()
        self.adnalyerManager.reset()
    }
    
    public override func onUpdateConfig(pluginConfig: Any) {
        super.onUpdateConfig(pluginConfig: pluginConfig)
        guard let config = pluginConfig as? AnalyticsConfig else {
            PKLog.error("wrong config, could not setup youbora manager")
            self.messageBus?.post(PlayerEvent.PluginError(nsError: YouboraPluginError.failedToSetupYouboraManager.asNSError))
            return
        }
        self.setupYoubora(withConfig: config)
    }
    
    public override func destroy() {
        // we must call `endedHandler()` when destroyed so youbora will know player stopped playing content.
        self.endedHandler()
        self.stopMonitoring()
        // remove ad observers
        self.messageBus?.removeObserver(self, events: [AdEvent.adCuePointsUpdate, AdEvent.allAdsCompleted])
        AppStateSubject.shared.remove(observer: self)
        super.destroy()
    }
    
    /************************************************************/
    // MARK: - AnalytisPluginProtocol
    /************************************************************/
    
    override var playerEventsToRegister: [PlayerEvent.Type] {
        return [
            PlayerEvent.play,
            PlayerEvent.stopped,
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
            case let e where e.self == PlayerEvent.play:
                self.messageBus?.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    // play handler to start when asset starts loading.
                    // this point is the closest point to prepare call.
                    strongSelf.youboraManager.playHandler()
                    strongSelf.postEventLogWithMessage(message: "\(type(of: event))")
                }
            case let e where e.self == PlayerEvent.stopped:
                self.messageBus?.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    // we must call `endedHandler()` when stopped so youbora will know player stopped playing content.
                    strongSelf.endedHandler()
                    strongSelf.postEventLogWithMessage(message: "\(type(of: event))")
                }
            case let e where e.self == PlayerEvent.pause:
                self.messageBus?.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    strongSelf.youboraManager.pauseHandler()
                    strongSelf.postEventLogWithMessage(message: "\(type(of: event))")
                }
            case let e where e.self == PlayerEvent.playing:
                self.messageBus?.addObserver(self, events: [e.self]) { [weak self] event in
                    guard let strongSelf = self else { return }
                    if strongSelf.isFirstPlay {
                        strongSelf.isFirstPlay = false
                        strongSelf.youboraManager.joinHandler()
                        strongSelf.youboraManager.bufferedHandler()
                    } else {
                        strongSelf.youboraManager.resumeHandler()
                    }
                    strongSelf.postEventLogWithMessage(message: "\(String(describing: type(of: event)))")
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
                    if !strongSelf.shouldDelayEndedHandler {
                        strongSelf.youboraManager.endedHandler()
                    }
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
        
        self.messageBus?.addObserver(self, events: [AdEvent.adCuePointsUpdate]) { [weak self] event in
            if let hasPostRoll = event.adCuePoints?.hasPostRoll, hasPostRoll == true {
                self?.shouldDelayEndedHandler = true
            }
        }
        self.messageBus?.addObserver(self, events: [AdEvent.allAdsCompleted]) { [weak self] event in
            if let shouldDelayEndedHandler = self?.shouldDelayEndedHandler, shouldDelayEndedHandler == true {
                self?.shouldDelayEndedHandler = false
                self?.youboraManager.endedHandler()
            }
        }
    }
    
    /************************************************************/
    // MARK: - App State Handling
    /************************************************************/
    
    var observations: Set<NotificationObservation> {
        return [
            NotificationObservation(name: .UIApplicationWillTerminate) { [unowned self] in
                PKLog.debug("youbora plugin will terminate event received")
                // we must call `endedHandler()` when stopped so youbora will know player stopped playing content.
                self.endedHandler()
                AppStateSubject.shared.remove(observer: self)
            }
        ]
    }
    
    /************************************************************/
    // MARK: - Private
    /************************************************************/
    
    private func setupYoubora(withConfig config: AnalyticsConfig) {
        let options = config.params
        let optionsObject = NSDictionary(dictionary: options)
        self.youboraManager.setOptions(optionsObject)
    }
    
    private func startMonitoring() {
        // make sure to first stop monitoring in case we of uneven call to start/stop
        self.stopMonitoring()
        PKLog.debug("Start monitoring Youbora")
        self.youboraManager.startMonitoring(withPlayer: nil)
        PKLog.debug("Start monitoring Youbora Adnalyzer")
        // we start monitoring using messageBus object because he is the one handling our events not the player
        self.adnalyerManager.startMonitoring(withPlayer: self.messageBus)
    }
    
    private func stopMonitoring() {
        PKLog.debug("Stop monitoring using Youbora Adnalyzer")
        self.adnalyerManager.stopMonitoring()
        PKLog.debug("Stop monitoring using Youbora")
        self.youboraManager.stopMonitoring()
    }
    
    private func postEventLogWithMessage(message: String) {
        let eventLog = YouboraEvent.Report(message: message)
        self.messageBus?.post(eventLog)
    }
    
    private func endedHandler() {
        self.adnalyerManager.endedAdHandler()
        self.youboraManager.endedHandler()
    }
}
