//
//  PhoenixAnalyticsPlugin.swift
//  Pods
//
//  Created by Oded Klein on 27/11/2016.
//
//

import UIKit

public class PhoenixAnalyticsPlugin: PKPlugin, KalturaPluginManagerDelegate {

    private unowned var player: Player
    private var config: AnalyticsConfig!
    private var kalturaPluginManager: KalturaPluginManager!
    
    public static var pluginName: String = "PhoenixAnalytics"
    public weak var mediaEntry: MediaEntry?
    
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
    
    func pluginManagerDidSendAnalyticsEvent(action: PhoenixAnalyticsType) {
        PKLog.trace("Action: \(action)")
        
        var fileId = ""
        var baseUrl = ""
        var ks = ""
        var parterId = 0

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

        guard let mediaEntry = self.mediaEntry else {
            PKLog.error("send analytics failed due to nil mediaEntry")
            return
        }
        
        if let builder: KalturaRequestBuilder = BookmarkService.actionAdd(baseURL: baseUrl,
                                                                       partnerId: parterId,
                                                                       ks: ks,
                                                                       eventType: action.rawValue.uppercased(),
                                                                       currentTime: self.player.currentTime.toInt32(),
                                                                       assetId: mediaEntry.id,
                                                                       fileId: fileId) {
            builder.set { (response: Response) in
                PKLog.trace("Response: \(response)")
                if response.statusCode == 0 {
                    PKLog.trace("\(response.data)")
                    if let data : [String: Any] = response.data as! [String : Any]? {
                        if let result = data["result"] as! [String: Any]? {
                            if let errorData = result["error"] as! [String: Any]? {
                                if let errorCode = errorData["code"] as? Int, errorCode == 4001 {
                                    
                                    self.kalturaPluginManager.reportConcurrencyEvent()
                                }
                            }
                        }
                    }
                }
            }
            USRExecutor.shared.send(request: builder.build())
        }
    }
}



