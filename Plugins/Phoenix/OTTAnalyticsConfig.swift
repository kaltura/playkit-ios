//
//  OTTAnalyticsConfig.swift
//  Pods
//
//  Created by Gal Orlanczyk on 25/06/2017.
//
//

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
    
    public init(baseUrl: String, timerInterval: TimeInterval, ks: String, partnerId: Int) {
        self.ks = ks
        self.partnerId = partnerId
        super.init(baseUrl: baseUrl, timerInterval: timerInterval)
    }
}

@objc public class TVPAPIAnalyticsPluginConfig: OTTAnalyticsPluginConfig {
    
    let initObject: [String: Any]
    
    public init(baseUrl: String, timerInterval: TimeInterval, initObject: [String: Any]) {
        self.initObject = initObject
        super.init(baseUrl: baseUrl, timerInterval: timerInterval)
    }
}
