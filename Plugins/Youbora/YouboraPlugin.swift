// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

public class YouboraPlugin: BasePlugin, AppStateObservable {
    
    struct CustomPropertyKey {
        static let sessionId = "sessionId"
    }
    
    public override class var pluginName: String {
        return "YouboraPlugin"
    }
    
    /// The key for enabling adnalyzer in the config dictionary
    @objc public static let enableSmartAdsKey = "enableSmartAds"
    
    public static let kaltura = "kaltura"
    
    /// The youbora plugin inheriting from `YBPluginGeneric`
    /// - important: Make sure to call `playHandler()` at the start of any flow before everying
    /// (for example before pre-roll in ads) also make sure to call `endedHandler() at the end of every flow
    /// (for example when we have post-roll call it after the ad).
    /// In addition, when content ends in the middle also make sure to call `endedHandler()`
    /// otherwise youbora will wait for /stop event and you could not start new content events until /stop is received.
    private var youboraManager: YouboraManager
    private var adnalyzerManager: YouboraAdnalyzerManager?
    private var npawPlugin: YouboraNPAWPlugin?
    
    /// The plugin's config
    var config: AnalyticsConfig
    
    /************************************************************/
    // MARK: - PKPlugin
    /************************************************************/
    
    public required init(player: Player, pluginConfig: Any?, messageBus: MessageBus) throws {
        guard let config = pluginConfig as? AnalyticsConfig else {
            PKLog.error("missing plugin config")
            throw PKPluginError.missingPluginConfig(pluginName: YouboraPlugin.pluginName)
        }
        self.config = config
        /// initialize youbora components
        let options = config.params
        let optionsObject = NSDictionary(dictionary: options)
        //self.npawPlugin = YouboraNPAWPlugin(options: options) //TODO Change this to real options
        self.youboraManager = YouboraManager(player: player)
        self.adnalyzerManager = YouboraAdnalyzerManager(player: player)
        self.npawPlugin?.adapter = self.youboraManager
        self.npawPlugin?.adsAdapter = self.adnalyzerManager
        
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
        self.stopMonitoring()
        //self.adnalyzerManager?.reset()
        //self.youboraManager.reset()
        self.setupYoubora(withConfig: self.config)
    }
    
    public override func onUpdateConfig(pluginConfig: Any) {
        super.onUpdateConfig(pluginConfig: pluginConfig)
        guard let config = pluginConfig as? AnalyticsConfig else {
            PKLog.error("wrong config, could not setup youbora manager")
            self.messageBus?.post(PlayerEvent.PluginError(nsError: YouboraPluginError.failedToSetupYouboraManager.asNSError))
            return
        }
        self.config = config
        self.setupYoubora(withConfig: config)
        // make sure to create or destroy adnalyzer based on config
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
    // MARK: - App State Handling
    /************************************************************/
    
    public var observations: Set<NotificationObservation> {
        return [
            NotificationObservation(name: .UIApplicationWillTerminate) { [unowned self] in
                PKLog.debug("youbora plugin will terminate event received")
                // we must call `endedHandler()` when stopped so youbora will know player stopped playing content.
                self.endedHandler()
                AppStateSubject.shared.remove(observer: self)
            },
            NotificationObservation(name: .UIApplicationDidEnterBackground) { [unowned self] in
                // when entering background we should call `endedHandler()` to make sure coming back starts a new session.
                // otherwise events could be lost (youbora only retry sending events for 5 minutes).
                self.endedHandler()
                // reset the youbora plugin for background handling to start playing again when we return.
                self.youboraManager.resetForBackground()
            }
        ]
    }
    
    /************************************************************/
    // MARK: - Private
    /************************************************************/
    
    private func setupYoubora(withConfig config: AnalyticsConfig) {
        var options = config.params
        self.addCustomProperties(toOptions: &options)
        let optionsObject = NSDictionary(dictionary: options)
        //self.npawPlugin.setOptions(options) //TODO Change this to real options
    }
    
    private func startMonitoring() {
        // make sure to first stop monitoring in case we of uneven call to start/stop
        self.stopMonitoring()
        PKLog.debug("Start monitoring Youbora")
        self.npawPlugin?.adapter = self.youboraManager
        self.npawPlugin?.adsAdapter = self.adnalyzerManager
    }
    
    private func stopMonitoring() {
        self.npawPlugin?.removeAdsAdapter()
        PKLog.debug("Stop monitoring using Youbora")
        self.npawPlugin?.removeAdapter()
    }
    
    private func endedHandler() {
        self.npawPlugin?.adapter?.fireStop()
        self.npawPlugin?.adsAdapter?.fireStop()
    }
    
    private func addCustomProperties(toOptions options: inout [String: Any]) {
        guard let player = self.player else {
            PKLog.warning("couldn't add custom properties, player instance is nil")
            return
        }
        let propertiesKey = "properties"
        if var properties = options[propertiesKey] as? [String: Any] { // if properties already exists override the custom properties only
            properties[CustomPropertyKey.sessionId] = player.sessionId
            options[propertiesKey] = properties
        } else { // if properties doesn't exist then add
            options[propertiesKey] = [CustomPropertyKey.sessionId: player.sessionId]
        }
    }
}
