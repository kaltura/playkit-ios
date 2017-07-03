// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license,
// unless a different license for a particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

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
            "initObj": ["": ""]
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

