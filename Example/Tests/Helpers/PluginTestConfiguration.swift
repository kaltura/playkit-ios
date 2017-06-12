//
//  AnalyticsPluginConfig.swift
//  PlayKit
//
//  Created by Gal Orlanczyk on 08/02/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

enum PluginTestConfiguration {
    case TVPAPI
    case Phoenix
    
    mutating func next() {
        switch self {
        case .TVPAPI: self = .Phoenix
        case .Phoenix: self = .TVPAPI
        }
    }
    
    var pluginName: String {
        switch self {
        case .TVPAPI: return "TVPAPIAnalyticsPluginMock" 
        case .Phoenix: return "PhoenixAnalyticsPluginMock"
        }
    }
    
    var paramsDict: [String : Any] {
        switch self {
        case .TVPAPI: return [
            "fileId": "464302",
            "baseUrl": "http://tvpapi-preprod.ott.kaltura.com/v3_9/gateways/jsonpostgw.aspx?",
            "timerInterval":30,
            "initObj": ""
            ]
        case .Phoenix: return [
            "fileId": "464302",
            "baseUrl": "http://api-preprod.ott.kaltura.com/v4_1/api_v3/",
            "partnerId": 198,
            "timerInterval": 30
            ]
        }
    }
}

