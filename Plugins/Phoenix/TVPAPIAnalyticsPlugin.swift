//
//  TVPAPIAnalyticsPlugin.swift
//  Pods
//
//  Created by Oded Klein on 11/12/2016.
//
//

import UIKit
import SwiftyJSON

public class TVPAPIAnalyticsPlugin: PKPlugin, KalturaPluginManagerDelegate {

    public static var pluginName: String = "TVPAPIAnalytics"
    
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
        
        var fileId = ""
        var baseUrl = ""
        var initObj : JSON? = nil
        
        let method = action == .hit ? "MediaHit" : "MediaMark"

        if let url = self.config.params["baseUrl"] as? String {
            baseUrl = url
        }
        
        if let fId = self.config.params["fileId"] as? String {
            fileId = fId
        }

        if let obj = self.config.params["initObj"] as? JSON {
            initObj = obj
        }
        
        baseUrl = "\(baseUrl)m=\(method)"
        
        if let builder: KalturaRequestBuilder = MediaMarkService.sendTVPAPIEVent(baseURL: baseUrl,
                                                                                 initObj: initObj,
                                                                                 eventType: action.rawValue,
                                                                                 currentTime: Float(self.player.currentTime),
                                                                                 assetId: self.mediaEntry.id,
                                                                                 fileId: fileId) {
            builder.set { (response: Response) in
                
                PKLog.trace("Response: \(response)")
                if response.statusCode == 0 {
                    
                    PKLog.trace("\(response.data)")
                    if let data : [String: Any] = response.data as! [String : Any]? {
                        if let result = data["concurrent"] as! [String: Any]? {
                            self.kalturaPluginManager.reportConcurrencyEvent()
                        }
                    }
 
                }
            }
            
            USRExecutor.shared.send(request: builder.build())

        }
        
    }
}
