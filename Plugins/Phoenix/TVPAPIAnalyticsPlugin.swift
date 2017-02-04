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
    public var mediaEntry: MediaEntry?
    
    private var player: Player
    private var config: AnalyticsConfig?
    private var kalturaPluginManager: KalturaPluginManager
    
    /************************************************************/
    // MARK: - PKPlugin
    /************************************************************/
    
    public required init(player: Player, pluginConfig: Any?, messageBus: MessageBus) {
        self.player = player
        if let aConfig = pluginConfig as? AnalyticsConfig {
            self.config = aConfig
        }
        self.kalturaPluginManager = KalturaPluginManager(player: player, pluginConfig: pluginConfig, messageBus: messageBus)
        self.kalturaPluginManager.delegate = self
    }
    
    public func onLoad(mediaConfig: MediaConfig) {
        PKLog.trace("plugin \(type(of:self)) onLoad with media config: \(mediaConfig)")
        self.mediaEntry = mediaConfig.mediaEntry
    }
    
    public func onUpdateMedia(mediaConfig: MediaConfig) {
        PKLog.trace("plugin \(type(of:self)) onUpdateMedia with media config: \(mediaConfig)")
        self.mediaEntry = mediaConfig.mediaEntry
    }
    
    public func destroy() {
        self.kalturaPluginManager.destroy()
    }
    
    /************************************************************/
    // MARK: - KalturaPluginManagerDelegate
    /************************************************************/
    
    internal func pluginManagerDidSendAnalyticsEvent(action: PhoenixAnalyticsType) {
        PKLog.trace("Action: \(action)")
        
        var fileId = ""
        var baseUrl = ""
        var initObj : JSON? = nil
        
        let method = action == .hit ? "MediaHit" : "MediaMark"

        if let url = self.config?.params["baseUrl"] as? String {
            baseUrl = url
        }
        if let fId = self.config?.params["fileId"] as? String {
            fileId = fId
        }
        if let obj = self.config?.params["initObj"] as? JSON {
            initObj = obj
        }
        
        baseUrl = "\(baseUrl)m=\(method)"
        
        guard let mediaEntry = self.mediaEntry else {
            PKLog.error("send analytics failed due to nil mediaEntry")
            return
        }
        
        if let builder: RequestBuilder = MediaMarkService.sendTVPAPIEVent(baseURL: baseUrl,
                                                                                 initObj: initObj,
                                                                                 eventType: action.rawValue,
                                                                                 currentTime: self.player.currentTime.toInt32(),
                                                                                 assetId: mediaEntry.id,
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
