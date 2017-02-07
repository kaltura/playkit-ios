//
//  PhoenixAnalyticsPlugin.swift
//  Pods
//
//  Created by Oded Klein on 27/11/2016.
//
//

import UIKit

public class PhoenixAnalyticsPlugin: BaseOTTAnalyticsPlugin, KalturaOTTAnalyticsPluginProtocol {
    
    public override class var pluginName: String { return "PhoenixAnalytics" }
    
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
        
        guard let mediaEntry = self.mediaEntry else {
            PKLog.error("send analytics failed due to nil mediaEntry")
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
                guard let data = response.data as? [String : Any] else { return }
                guard let result = data["result"] as? [String: Any] else { return }
                guard let errorData = result["error"] as? [String: Any] else { return }
                guard let errorCode = errorData["code"] as? Int, errorCode == 4001 else { return }
                self.reportConcurrencyEvent()
            }
        }
        
        return requestBuilder.build()
    }
    
    func send(request: Request) {
        USRExecutor.shared.send(request: request)
    }
}


