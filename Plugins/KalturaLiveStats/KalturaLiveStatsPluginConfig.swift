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

@objc public class KalturaLiveStatsPluginConfig: NSObject {
    
    let entryId: String
    let partnerId: Int
    
    @objc public var baseUrl = "https://stats.kaltura.com/api_v3/index.php"
    
    @objc public init(entryId: String, partnerId: Int) {
        self.entryId = entryId
        self.partnerId = partnerId
    }
}
