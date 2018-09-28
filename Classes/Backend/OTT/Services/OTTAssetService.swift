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

class OTTAssetService {

    internal static func getPlaybackContext(baseURL: String, ks: String, assetId: String, type: AssetTypeAPI, playbackContextOptions: PlaybackContextOptions) -> KalturaRequestBuilder? {

        guard let request: KalturaRequestBuilder = KalturaRequestBuilder(url: baseURL, service: "asset", action: "getPlaybackContext") else {
            return nil
        }
        
        return request
            .setBody(key: "assetId", value: JSON(assetId))
            .setBody(key: "ks", value: JSON(ks))
            .setBody(key: "assetType", value: JSON(type.asString))
            .setBody(key: "contextDataParams", value: JSON(playbackContextOptions.toDictionary()))
    }
    
    internal static func getMetaData(baseURL: String, ks: String, assetId: String, refType: AssetReferenceTypeAPI) -> KalturaRequestBuilder? {
        
        guard let request: KalturaRequestBuilder = KalturaRequestBuilder(url: baseURL, service: "asset", action: "get") else {
            return nil
        }
        
        return request
            .setBody(key: "ks", value: JSON(ks))
            .setBody(key: "id", value: JSON(assetId))
            .setBody(key: "assetReferenceType", value: JSON(refType.asString))
    }
}

struct PlaybackContextOptions {

    var playbackContextType: PlaybackTypeAPI
    var protocls: [String]
    var assetFileIds: [String]?
    var referrer: String?
    
    func toDictionary() -> [String: Any] {

        var dict: [String: Any] = [:]
        dict["context"] = playbackContextType.asString
        dict["mediaProtocols"] = protocls
        if let fileIds = self.assetFileIds {
            dict["assetFileIds"] = fileIds.joined(separator: ",")
        }
        if let referrer = self.referrer {
            dict["referrer"] = referrer
        }
        return dict
    }
}
