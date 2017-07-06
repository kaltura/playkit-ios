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

@objc public class OTTAnalyticsPluginConfig: NSObject {
    
    let baseUrl: String
    let timerInterval: TimeInterval
    
    init(baseUrl: String, timerInterval: TimeInterval) {
        self.baseUrl = baseUrl
        self.timerInterval = timerInterval
    }
}

@objc public class PhoenixAnalyticsPluginConfig: OTTAnalyticsPluginConfig {
    
    let ks: String
    let partnerId: Int
    
    @objc public init(baseUrl: String, timerInterval: TimeInterval, ks: String, partnerId: Int) {
        self.ks = ks
        self.partnerId = partnerId
        super.init(baseUrl: baseUrl, timerInterval: timerInterval)
    }
}

@objc public class TVPAPIAnalyticsPluginConfig: OTTAnalyticsPluginConfig {
    
    let initObject: [String: Any]
    
    @objc public init(baseUrl: String, timerInterval: TimeInterval, initObject: [String: Any]) {
        self.initObject = initObject
        super.init(baseUrl: baseUrl, timerInterval: timerInterval)
    }
}
