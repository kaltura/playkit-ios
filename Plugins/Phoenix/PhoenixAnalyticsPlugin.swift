//
//  PhoenixAnalyticsPlugin.swift
//  Pods
//
//  Created by Oded Klein on 27/11/2016.
//
//

import UIKit

public class PhoenixAnalyticsPlugin: BaseOTTAnalyticsPlugin {
    
    public override class var pluginName: String { return "PhoenixAnalytics" }
    
    /************************************************************/
    // MARK: - KalturaOTTAnalyticsPluginProtocol
    /************************************************************/
    
    override func buildRequest(ofType type: OTTAnalyticsEventType) -> Request? {
        var fileId = ""
        var baseUrl = ""
        var ks = ""
        var parterId = 0
        
        if let url = self.config?.params["baseUrl"] as? String {
            baseUrl = url
        }
        
        if let fId = self.config?.params["fileId"] as? String {
            fileId = fId
        }
        
        if let theKs = self.config?.params["ks"] as? String {
            ks = theKs
        }
        
        if let pId = self.config?.params["partnerId"] as? Int {
            parterId = pId
        }
        
        guard let mediaEntry = self.player.mediaEntry else {
            PKLog.error("send analytics failed due to nil mediaEntry")
            self.messageBus.post(PlayerEvent.PluginError(error: AnalyticsPluginError.missingMediaEntry))
            return nil
        }
        
        guard let requestBuilder: KalturaRequestBuilder = BookmarkService.actionAdd(baseURL: baseUrl,
                                                                          partnerId: parterId,
                                                                          ks: ks,
                                                                          eventType: type.rawValue.uppercased(),
                                                                          currentTime: self.player.currentTime.toInt32(),
                                                                          assetId: mediaEntry.id,
                                                                          fileId: fileId) else {
            return nil
        }
        
        requestBuilder.set { (response: Response) in
            PKLog.trace("Response: \(response)")
            if response.statusCode == 0 {
                PKLog.trace("\(response.data)")
                guard let data = response.data as? [String: Any] else { return }
                guard let result = data["result"] as? [String: Any] else { return }
                guard let errorData = result["error"] as? [String: Any] else { return }
                guard let errorCode = errorData["code"] as? Int, errorCode == 4001 else { return }
                self.reportConcurrencyEvent()
            }
        }
        
        return requestBuilder.build()
    }
}


