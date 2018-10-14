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
import SwiftyJSON
import KalturaNetKit

public class TVPAPIAnalyticsPlugin: BaseOTTAnalyticsPlugin {
    
    public override class var pluginName: String { return "TVPAPIAnalytics" }
    
    var config: TVPAPIAnalyticsPluginConfig! {
        didSet {
            self.interval = config.timerInterval
        }
    }
    
    public required init(player: Player, pluginConfig: Any?, messageBus: MessageBus) throws {
        try super.init(player: player, pluginConfig: pluginConfig, messageBus: messageBus)
        guard let config = pluginConfig as? TVPAPIAnalyticsPluginConfig else {
            PKLog.error("missing/wrong plugin config")
            throw PKPluginError.missingPluginConfig(pluginName: TVPAPIAnalyticsPlugin.pluginName)
        }
        self.config = config
        self.interval = config.timerInterval
    }
    
    public override func onUpdateConfig(pluginConfig: Any) {
        super.onUpdateConfig(pluginConfig: pluginConfig)
        
        guard let config = pluginConfig as? TVPAPIAnalyticsPluginConfig else {
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
        guard let player = self.player else { return nil }
        
        guard let mediaEntry = player.mediaEntry else {
            PKLog.error("send analytics failed due to nil mediaEntry")
            return nil
        }
        
        let method = type == .hit ? "MediaHit" : "MediaMark"

        let baseUrl = "\(self.config.baseUrl)m=\(method)"
        
        guard let requestBuilder: RequestBuilder = MediaMarkService.sendTVPAPIEVent(baseURL: baseUrl,
                                                                                    initObj: self.config.initObject,
                                                                                    eventType: type.rawValue,
                                                                                    currentTime: player.currentTime.toInt32(),
                                                                                    assetId: mediaEntry.id,
                                                                                    fileId: self.fileId ?? "") else {
            return nil
        }
        requestBuilder.set(responseSerializer: StringSerializer())
        requestBuilder.set { (response: Response) in
            PKLog.verbose("Response: \(response)")
            if response.statusCode == 0 {
                PKLog.verbose("\(String(describing: response.data))")
                guard let data = response.data as? String, data.lowercased() == "\"concurrent\"" else { return }
                self.reportConcurrencyEvent()
            }
        }
        
        return requestBuilder.build()
    }
}

