//
//  KalturaLiveStatsPluginConfig.swift
//  Pods
//
//  Created by Gal Orlanczyk on 28/06/2017.
//
//

import Foundation

@objc public class KalturaLiveStatsPluginConfig: NSObject {
    
    let entryId: String
    let partnerId: Int
    
    @objc public var baseUrl = "https://stats.kaltura.com/api_v3/index.php"
    
    @objc public init(entryId: String, partnerId: Int) {
        self.entryId = entryId
        self.partnerId = partnerId
    }
}
