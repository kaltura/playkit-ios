// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import UIKit
import SwiftyJSON
import KalturaNetKit


class OVPBaseEntryService {

    internal static func list(baseURL: String, ks: String,entryID: String) -> KalturaRequestBuilder? {
        
        if let request: KalturaRequestBuilder = KalturaRequestBuilder(url: baseURL, service: "baseEntry", action: "list") {
            let responseProfile = ["fields": "mediaType,dataUrl,id,name,duration,msDuration,flavorParamsIds,tags", "type": 1] as [String: Any]
            request.setBody(key: "ks", value: JSON(ks))
                .setBody(key: "responseProfile", value: JSON(responseProfile))
                .setBody(key: "filter:redirectFromEntryId", value: JSON(entryID))
            return request
        } else {
            return nil
        }
    }
    
    internal static func metadata(baseURL: String, ks: String,entryID: String) -> KalturaRequestBuilder? {
        
        if let request: KalturaRequestBuilder = KalturaRequestBuilder(url: baseURL, service: "metadata_metadata", action: "list") {
            request.setBody(key: "ks", value: JSON(ks))
                .setBody(key: "filter:objectType", value: JSON("KalturaMetadataFilter"))
                .setBody(key: "filter:objectIdEqual", value: JSON(entryID))
                .setBody(key: "filter:metadataObjectTypeEqual", value: JSON("1"))
            return request
        } else {
            return nil
        }
    }

    internal static func getContextData(baseURL: String, ks: String,entryID: String) -> KalturaRequestBuilder? {
        
        if let request: KalturaRequestBuilder = KalturaRequestBuilder(url: baseURL, service: "baseEntry", action: "getContextData") {
            let contextData: [String: Any] = [String: Any]()
            request.setBody(key: "ks", value: JSON(ks))
                .setBody(key: "entryId", value: JSON(entryID))
                .setBody(key: "contextDataParams", value: JSON(contextData))
            return request
        } else {
            return nil
        }
        
    }
    
    internal static func getPlaybackContext(baseURL: String, ks: String, entryID: String, referrer: String?) -> KalturaRequestBuilder? {
        if let request: KalturaRequestBuilder = KalturaRequestBuilder(url: baseURL, service: "baseEntry", action: "getPlaybackContext") {
            var contextData: [String: Any] = ["objectType": "KalturaContextDataParams"]
            if let r = referrer {
                contextData["referrer"] = r
            }
            request.setBody(key: "ks", value: JSON(ks))
                .setBody(key: "entryId", value: JSON(entryID))
                .setBody(key: "contextDataParams", value: JSON(contextData))
            return request
        } else {
            return nil
        }
    }

}

