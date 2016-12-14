//
//  PhoenixAnalyticsPlugin.swift
//  Pods
//
//  Created by Oded Klein on 27/11/2016.
//
//

import UIKit

public class PhoenixAnalyticsPlugin: PKPlugin, KalturaPluginManagerDelegate {

    public static var pluginName: String = "PhoenixAnalytics"

    private var player: Player!
    private var config: AnalyticsConfig!
    private var mediaEntry: MediaEntry!

    private var kalturaPluginManager: KalturaPluginManager!
    
    required public init() {
        
    }
    
    public func load(player: Player, mediaConfig: MediaEntry, pluginConfig: Any?, messageBus: MessageBus) {
        self.kalturaPluginManager = KalturaPluginManager()
        
        self.mediaEntry = mediaConfig
        if let aConfig = pluginConfig as? AnalyticsConfig {
            self.player = player
            self.config = aConfig
        }

        self.kalturaPluginManager.delegate = self
        self.kalturaPluginManager.load(player: player, pluginConfig: pluginConfig, messageBus: messageBus)

    }
    
    public func destroy() {
        self.kalturaPluginManager.destroy()
    }
    
    internal func sendAnalyticsEvent(action: PhoenixAnalyticsType) {
        PKLog.trace("Action: \(action)")
        
        var fileId = "464302"
        var baseUrl = ""
        var ks = ""
        var parterId = 198

        if let url = self.config.params["baseUrl"] as? String {
            baseUrl = url
        }

        if let fId = self.config.params["fileId"] as? String {
            fileId = fId
        }

        if let theKs = self.config.params["ks"] as? String {
            ks = theKs
        }

        if let pId = self.config.params["partnerId"] as? Int {
            parterId = pId
        }

        if let builder: KalturaRequestBuilder = BookmarkService.actionAdd(baseURL: baseUrl,
                                                                       partnerId: parterId,
                                                                       ks: ks,
                                                                       eventType: action.rawValue.uppercased(),
                                                                       currentTime: Float(self.player.currentTime),
                                                                       assetId: self.mediaEntry.id,
                                                                       fileId: fileId) {
            builder.set { (response: Response) in
                
                PKLog.trace("Response: \(response)")
                
            }
            
            USRExecutor.shared.send(request: builder.build())
        }
        
    }
    
}






