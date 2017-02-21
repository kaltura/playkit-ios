//
//  BaseAnalyticsPlugin.swift
//  Pods
//
//  Created by Gal Orlanczyk on 17/02/2017.
//
//

import Foundation

/// `AnalyticsError` represents analytics plugins (kaltura stats, kaltura live stats, phoenix and tvpapi) common errors.
enum AnalyticsError: PKError {
    
    case missingMediaEntry
    case missingInitObject
    
    static let Domain = PKErrorDomain.AnalyticsPlugin
    
    var code: Int {
        switch self {
        case .missingMediaEntry: return 3000
        case .missingInitObject: return 3001
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

/// class `BaseAnalyticsPlugin` is a base plugin object used for analytics plugin subclasses
public class BaseAnalyticsPlugin: AnalyticsPluginProtocol {
    
    /// abstract implementation subclasses will have names
    public class var pluginName: String {
        fatalError("abstract property should be overriden in subclass")
    }
    
    unowned var player: Player
    unowned var messageBus: MessageBus
    public weak var mediaEntry: MediaEntry?
    
    var config: AnalyticsConfig?
    var isFirstPlay: Bool = true
    
    /************************************************************/
    // MARK: - PKPlugin
    /************************************************************/
    
    public required init(player: Player, pluginConfig: Any?, messageBus: MessageBus) {
        PKLog.info("initializing plugin \(type(of:self))")
        self.player = player
        self.messageBus = messageBus
        if let aConfig = pluginConfig as? AnalyticsConfig {
            self.config = aConfig
        } else {
            PKLog.error("There is no Analytics Config.")
        }
        self.registerEvents()
    }
    
    public func onLoad(mediaConfig: MediaConfig) {
        PKLog.info("plugin \(type(of:self)) onLoad with media config: \(mediaConfig)")
        self.mediaEntry = mediaConfig.mediaEntry
    }
    
    public func onUpdateMedia(mediaConfig: MediaConfig) {
        PKLog.info("plugin \(type(of:self)) onUpdateMedia with media config: \(mediaConfig)")
        self.mediaEntry = mediaConfig.mediaEntry
    }
    
    public func destroy() {
        PKLog.info("destroying plugin \(type(of:self))")
        self.messageBus.removeObserver(self, events: playerEventsToRegister)
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
