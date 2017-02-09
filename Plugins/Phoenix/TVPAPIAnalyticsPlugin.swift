//
//  TVPAPIAnalyticsPlugin.swift
//  Pods
//
//  Created by Oded Klein on 11/12/2016.
//
//

import UIKit
import SwiftyJSON

public class TVPAPIAnalyticsPlugin: BaseOTTAnalyticsPlugin {
    
    public override class var pluginName: String { return "TVPAPIAnalytics" }
    
    /************************************************************/
    // MARK: - KalturaOTTAnalyticsPluginProtocol
    /************************************************************/
    
    override func buildRequest(ofType type: OTTAnalyticsEventType) -> Request? {
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
}

