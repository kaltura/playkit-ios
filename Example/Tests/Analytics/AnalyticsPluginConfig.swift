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

enum AnalyticsPluginConfig {
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
        case .TVPAPI: return PhoenixAnalyticsPluginMock.pluginName
        case .Phoenix: return TVPAPIAnalyticsPluginMock.pluginName
        }
    }
    
    var paramsDict: [String : Any] {
        switch self {
        case .TVPAPI: return [
            "fileId": "464302",
            "baseUrl": "http://tvpapi-preprod.ott.kaltura.com/v3_9/gateways/jsonpostgw.aspx?",
            "timerInterval":30000,
            "initObj": ""
            ]
        case .Phoenix: return [
            "fileId": "464302",
            "baseUrl": "http://api-preprod.ott.kaltura.com/v4_1/api_v3/",
            "ks": "djJ8MTk4fL1W9Rs4udDqNt_CpUT9dJKk1laPk9_XnBtUaq7PXVcVPYrXz2shTbKSW1G5Lhn_Hvbbnh0snheANOmSodl7Puowxhk2WYkpmNugi9vNAg5C",
            "partnerId": 198,
            "timerInterval": 30
            ]
        }
    }
}

