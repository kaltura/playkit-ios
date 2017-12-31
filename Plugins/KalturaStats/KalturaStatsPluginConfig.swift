// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import Foundation
import SwiftyJSON

@objc public class KalturaStatsPluginConfig: NSObject {
    
    private let defaultBaseUrl = "https://stats.kaltura.com/api_v3/index.php"
    
    let applicationId = Bundle.main.bundleIdentifier
    
    @objc public var uiconfId: Int
    @objc public var partnerId: Int
    @objc public var entryId: String
    
    @objc public var baseUrl: String
    @objc public var userId: String?
    @objc public var contextId: Int = -1 // need to be greater then 0 to be valid
    
    @objc public init(uiconfId: Int, partnerId: Int, entryId: String) {
        self.baseUrl = defaultBaseUrl
        self.uiconfId = uiconfId
        self.partnerId = partnerId
        self.entryId = entryId
    }
    
    public static func parse(json: JSON) -> KalturaStatsPluginConfig? {
        guard let jsonDictionary = json.dictionary else { return nil }
        
        guard let uiconfId = jsonDictionary["uiconfId"]?.int,
            let entryId = jsonDictionary["entryId"]?.string,
            let partnerId = jsonDictionary["partnerId"]?.int else { return nil }
        
        let config = KalturaStatsPluginConfig(uiconfId: uiconfId, partnerId: partnerId, entryId: entryId)
        
        if let baseUrl = jsonDictionary["baseUrl"]?.string, baseUrl != "" {
            config.baseUrl = baseUrl
        }
        if let userId = jsonDictionary["userId"]?.string {
            config.userId = userId
        }
        if let contextId = jsonDictionary["contextId"]?.int {
            config.contextId = contextId
        }
        
        return config
    }
}
