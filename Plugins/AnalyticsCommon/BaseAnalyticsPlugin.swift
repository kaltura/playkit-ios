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

/************************************************************/
// MARK: - BaseAnalyticsPlugin
/************************************************************/

/// class `BaseAnalyticsPlugin` is a base plugin object used for analytics plugin subclasses
@objc public class BaseAnalyticsPlugin: BasePlugin, AnalyticsPluginProtocol {
    
    var config: AnalyticsConfig?
    /// indicates whether we played for the first time or not.
    @objc public var isFirstPlay: Bool = true
    
    /************************************************************/
    // MARK: - PKPlugin
    /************************************************************/
    
    @objc public required init(player: Player, pluginConfig: Any?, messageBus: MessageBus) throws {
        try super.init(player: player, pluginConfig: pluginConfig, messageBus: messageBus)
        if let aConfig = pluginConfig as? AnalyticsConfig {
            self.config = aConfig
        } else {
            PKLog.warning("There is no Analytics Config! for \(type(of: self))")
        }
        self.registerEvents()
    }
    
    public override func onUpdateMedia(mediaConfig: MediaConfig) {
        super.onUpdateMedia(mediaConfig: mediaConfig)
        self.isFirstPlay = true
    }
    
    public override func onUpdateConfig(pluginConfig: Any) {
        super.onUpdateConfig(pluginConfig: pluginConfig)
        
        guard let config = pluginConfig as? AnalyticsConfig else {
            PKLog.error("plugin configis wrong")
            return
        }
        
        PKLog.verbose("new config::\(String(describing: config))")
        self.config = config
    }
    
    public override func destroy() {
        self.messageBus?.removeObserver(self, events: playerEventsToRegister)
        super.destroy()
    }
    
    /************************************************************/
    // MARK: - AnalyticsPluginProtocol
    /************************************************************/
    
    /// default events to register
    @objc public var playerEventsToRegister: [PlayerEvent.Type] {
        fatalError("abstract property should be overriden in subclass")
    }
    
    @objc public func registerEvents() {
        fatalError("abstract func should be overriden in subclass")
    }
    
    @objc public func unregisterEvents() {
        fatalError("abstract func should be overriden in subclass")
    }
}
