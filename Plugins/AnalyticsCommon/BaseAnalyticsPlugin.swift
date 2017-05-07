//
//  BaseAnalyticsPlugin.swift
//  Pods
//
//  Created by Gal Orlanczyk on 17/02/2017.
//
//

import Foundation

/************************************************************/
// MARK: - AnalyticsPluginError
/************************************************************/

/// `AnalyticsError` represents analytics plugins (kaltura stats, kaltura live stats, phoenix and tvpapi) common errors.
enum AnalyticsPluginError: PKError {
    
    case missingMediaEntry
    case missingInitObject
    
    static let domain = "com.kaltura.playkit.error.analyticsPlugin"
    
    var code: Int {
        switch self {
        case .missingMediaEntry: return PKErrorCode.missingMediaEntry
        case .missingInitObject: return PKErrorCode.missingInitObject
        }
    }
    
    var errorDescription: String {
        switch self {
        case .missingMediaEntry: return "failed to send analytics event, mediaEntry is nil"
        case .missingInitObject: return "failed to send analytics event, missing initObj"
        }
    }
    
    var userInfo: [String: Any] {
        return [:]
    }
}

extension PKErrorDomain {
    @objc(AnalyticsPlugin) public static let analyticsPlugin = AnalyticsPluginError.domain
}

extension PKErrorCode {
    @objc(MissingMediaEntry) public static let missingMediaEntry = 2100
    @objc(MissingInitObject) public static let missingInitObject = 2101
}

/************************************************************/
// MARK: - BaseAnalyticsPlugin
/************************************************************/

/// class `BaseAnalyticsPlugin` is a base plugin object used for analytics plugin subclasses
@objc public class BaseAnalyticsPlugin: BasePlugin, AnalyticsPluginProtocol {
    
    var config: AnalyticsConfig?
    /// indicates whether we played for the first time or not.
    var isFirstPlay: Bool = true
    
    /************************************************************/
    // MARK: - PKPlugin
    /************************************************************/
    
    public required init(player: Player, pluginConfig: Any?, messageBus: MessageBus) throws {
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
        
        PKLog.debug("new config::\(String(describing: config))")
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
    var playerEventsToRegister: [PlayerEvent.Type] {
        fatalError("abstract property should be overriden in subclass")
    }
    
    func registerEvents() {
        fatalError("abstract func should be overriden in subclass")
    }
}
