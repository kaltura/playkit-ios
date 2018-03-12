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

@objc public class KalturaStatsPluginConfig: NSObject {
    
    private let defaultBaseUrl = "https://stats.kaltura.com/api_v3/index.php"
    
    let applicationId = Bundle.main.bundleIdentifier
    
    @objc public var uiconfId: Int
    @objc public var partnerId: Int
    @objc public var entryId: String
    
    @objc public var baseUrl: String
    @objc public var userId: String?
    @objc public var contextId: Int = -1 // need to be greater then 0 to be valid
    @objc public var hasKanalony: Bool
    
    @objc public init(uiconfId: Int, partnerId: Int, entryId: String, hasKanalony: Bool) {
        self.baseUrl = defaultBaseUrl
        self.uiconfId = uiconfId
        self.partnerId = partnerId
        self.entryId = entryId
        self.hasKanalony = hasKanalony
    }
}
