//
//  PhoenixAnalyticsPlugin.swift
//  Pods
//
//  Created by Oded Klein on 27/11/2016.
//
//

import UIKit

class PhoenixAnalyticsPlugin: PKPlugin {

    enum PhoenixAnalyticsType {
        case hit
        case play
        case stop
        case pause
        case first_play
        case swoosh
        case load
        case finish
        case bitrate_change
        case error
    }

    private var player: Player!
    private var messageBus: MessageBus?
    private var config: AnalyticsConfig!
    private var mediaEntry: MediaEntry!

    public static var pluginName: String = "PhoenixAnalytics"
    
    required public init() {
        
    }
    
    public func load(player: Player, mediaConfig: MediaEntry, pluginConfig: Any?, messageBus: MessageBus) {
        
        self.messageBus = messageBus
        self.mediaEntry = mediaConfig
        
        if let aConfig = config as? AnalyticsConfig {
            self.config = aConfig
            self.player = player
        }
        
        registerToAllEvents()
        
    }
    
    public func destroy() {
        setMessageParams(action: .stop)
    }
    
    func registerToAllEvents() {
        
    }
    
    private func setMessageParams(action: PhoenixAnalyticsType) {
    
    }
    
}
