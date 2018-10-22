// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import UIKit
import KalturaNetKit

public class PhoenixAnalyticsPlugin: BaseOTTAnalyticsPlugin {
    
    public override class var pluginName: String { return "PhoenixAnalytics" }
    
    var config: PhoenixAnalyticsPluginConfig! {
        didSet {
            self.interval = config.timerInterval
        }
    }
    
    public required init(player: Player, pluginConfig: Any?, messageBus: MessageBus) throws {
        try super.init(player: player, pluginConfig: pluginConfig, messageBus: messageBus)
        guard let config = pluginConfig as? PhoenixAnalyticsPluginConfig else {
            PKLog.error("missing/wrong plugin config")
            throw PKPluginError.missingPluginConfig(pluginName: PhoenixAnalyticsPlugin.pluginName)
        }
        self.config = config
        self.interval = config.timerInterval
    }
    
    public override func onUpdateConfig(pluginConfig: Any) {
        super.onUpdateConfig(pluginConfig: pluginConfig)
        
        guard let config = pluginConfig as? PhoenixAnalyticsPluginConfig else {
            PKLog.error("plugin config is wrong")
            return
        }
        
        PKLog.debug("new config::\(String(describing: config))")
        self.config = config
    }
    
    /************************************************************/
    // MARK: - KalturaOTTAnalyticsPluginProtocol
    /************************************************************/
    
    override func buildRequest(ofType type: OTTAnalyticsEventType) -> Request? {
       
        var currentTime: Int32 = 0
        
        if type == .stop {
            currentTime = self.lastPosition
        } else {
            guard let player = self.player else {
                PKLog.error("send analytics failed due to nil associated player")
                return nil
            }
            
            currentTime = player.currentTime.toInt32()
        }
        
        guard let requestBuilder: KalturaRequestBuilder = BookmarkService.actionAdd(baseURL: config.baseUrl,
                                                                                    partnerId: config.partnerId,
                                                                                    ks: config.ks,
                                                                                    eventType: type.rawValue.uppercased(),
                                                                                    currentTime: currentTime,
                                                                                    assetId: mediaId ?? "",
                                                                                    fileId: fileId ?? "") else { return nil }
        
        requestBuilder.set { (response: Response) in
            PKLog.verbose("Response: \(response)")
            if response.statusCode == 0 {
                PKLog.verbose("\(String(describing: response.data))")
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
