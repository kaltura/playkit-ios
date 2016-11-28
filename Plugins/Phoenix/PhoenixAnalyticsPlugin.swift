//
//  PhoenixAnalyticsPlugin.swift
//  Pods
//
//  Created by Oded Klein on 27/11/2016.
//
//

import UIKit

class PhoenixAnalyticsPlugin: PKPlugin {

    private var player: Player!
    private var messageBus: MessageBus?
    private var config: AnalyticsConfig!

    public static var pluginName: String = "PhoenixAnalytics"
    
    required public init() {
        
    }
    
    public func load(player: Player, config: Any?, messageBus: MessageBus) {
        
        self.messageBus = messageBus
        
        if let aConfig = config as? AnalyticsConfig {
            self.config = aConfig
            self.player = player
        }
        
        registerToAllEvents()
        
    }
    
    public func destroy() {

    }
    
    func registerToAllEvents() {
        
    }
}
