//
//  BaseOTTAnalyticsPlugin.swift
//  Pods
//
//  Created by Gal Orlanczyk on 06/02/2017.
//
//

import Foundation

/// class `BaseOTTAnalyticsPlugin` is a base plugin object used for OTT analytics plugin subclasses
public class BaseOTTAnalyticsPlugin: PKPlugin {
    
    /// abstract implementation subclasses will have names
    public class var pluginName: String { return "" }
    
    unowned var player: Player
    unowned var messageBus: MessageBus
    public weak var mediaEntry: MediaEntry?
    
    var config: AnalyticsConfig?
    
    /************************************************************/
    // MARK: - PKPlugin
    /************************************************************/
    
    public required init(player: Player, pluginConfig: Any?, messageBus: MessageBus) {
        self.player = player
        self.messageBus = messageBus
        if let aConfig = pluginConfig as? AnalyticsConfig {
            self.config = aConfig
        }
    }
    
    public func onLoad(mediaConfig: MediaConfig) {
        PKLog.trace("plugin \(type(of:self)) onLoad with media config: \(mediaConfig)")
        self.mediaEntry = mediaConfig.mediaEntry
        AppStateSubject.shared.add(observer: self)
    }
    
    public func onUpdateMedia(mediaConfig: MediaConfig) {
        PKLog.trace("plugin \(type(of:self)) onUpdateMedia with media config: \(mediaConfig)")
        self.mediaEntry = mediaConfig.mediaEntry
        AppStateSubject.shared.add(observer: self)
    }
    
    public func destroy() {
        AppStateSubject.shared.remove(observer: self)
    }
}


/************************************************************/
// MARK: - App State Handling
/************************************************************/

extension BaseOTTAnalyticsPlugin: AppStateObservable {
    
    var observations: Set<NotificationObservation> {
        return [
            NotificationObservation(name: .UIApplicationWillTerminate) { [unowned self] in
                PKLog.trace("plugin: \(self) will terminate event received, sending analytics stop event")
                self.destroy()
            }
        ]
    }
}
