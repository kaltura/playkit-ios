//
//  KalturaStatsConfig.swift
//  Pods
//
//  Created by Gal Orlanczyk on 20/06/2017.
//
//

import Foundation

@objc public class KalturaStatsConfig: NSObject {
    
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
}
