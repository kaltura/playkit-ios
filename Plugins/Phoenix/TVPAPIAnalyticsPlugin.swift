//
//  TVPAPIAnalyticsPlugin.swift
//  Pods
//
//  Created by Oded Klein on 11/12/2016.
//
//

import UIKit
import SwiftyJSON

public class TVPAPIAnalyticsPlugin: BaseOTTAnalyticsPlugin, KalturaOTTAnalyticsPluginProtocol {
    
    public override class var pluginName: String { return "TVPAPIAnalytics" }
    
    var isFirstPlay: Bool = true
    var intervalOn: Bool = false
    var timer: Timer?
    var interval: TimeInterval = 30
    
    public override required init(player: Player, pluginConfig: Any?, messageBus: MessageBus) {
        super.init(player: player, pluginConfig: pluginConfig, messageBus: messageBus)
        self.registerToAllEvents()
    }
    
    public override func destroy() {
        self.sendAnalyticsEvent(ofType: .stop)
        self.stopTimer()
        super.destroy()
    }
    
    /************************************************************/
    // MARK: - KalturaOTTAnalyticsPluginProtocol
    /************************************************************/
    
    func buildRequest(ofType type: PhoenixAnalyticsType) -> Request? {
        var fileId = ""
        var baseUrl = ""
        var initObj : JSON? = nil
        
        let method = type == .hit ? "MediaHit" : "MediaMark"
        
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
            return nil
        }
        
        guard let requestBuilder: RequestBuilder = MediaMarkService.sendTVPAPIEVent(baseURL: baseUrl,
                                                                          initObj: initObj,
                                                                          eventType: type.rawValue,
                                                                          currentTime: self.player.currentTime.toInt32(),
                                                                          assetId: mediaEntry.id,
                                                                          fileId: fileId) else {
            return nil
        }
        
        requestBuilder.set { (response: Response) in
            PKLog.trace("Response: \(response)")
            if response.statusCode == 0 {
                PKLog.trace("\(response.data)")
                if let data : [String: Any] = response.data as! [String : Any]? {
                    if let result = data["concurrent"] as! [String: Any]? {
                        self.reportConcurrencyEvent()
                    }
                }
            }
        }
        
        return requestBuilder.build()
    }

    func send(request: Request) {
        USRExecutor.shared.send(request: request)
    }
}

