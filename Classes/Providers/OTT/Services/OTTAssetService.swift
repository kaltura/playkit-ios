//
//  Asset.swift
//  Pods
//
//  Created by Admin on 13/11/2016.
//
//

import UIKit
import SwiftyJSON

class OTTAssetService {

    internal static func get(baseURL: String, ks: String, assetId: String, type: AssetType) -> KalturaRequestBuilder? {

        if let request: KalturaRequestBuilder = KalturaRequestBuilder(url: baseURL, service: "asset", action: "get") {
            request
            .setBody(key: "id", value: JSON(assetId))
            .setBody(key: "ks", value: JSON(ks))
            .setBody(key: "type", value: JSON(type.rawValue))
            .setBody(key: "assetReferenceType", value: JSON(type.rawValue))
            .setBody(key: "with", value: JSON([["type": "files", "objectType": "KalturaCatalogWithHolder"]]))
            return request
        } else {
            return nil
        }
    }

    internal static func getPlaybackContext(baseURL: String, ks: String, assetId: String, type: AssetType, playbackContextOptions: PlaybackContextOptions) -> KalturaRequestBuilder? {

        if let request: KalturaRequestBuilder = KalturaRequestBuilder(url: baseURL, service: "asset", action: "getPlaybackContext") {
            request
            .setBody(key: "assetId", value: JSON(assetId))
            .setBody(key: "ks", value: JSON(ks))
            .setBody(key: "assetType", value: JSON(type.rawValue))
            .setBody(key: "contextDataParams", value: JSON(playbackContextOptions.toDictionary()))
            return request
        } else {
            return nil
        }

    }
}

struct PlaybackContextOptions {

    internal var playbackContextType: PlaybackContextType
    internal var protocls: [String]
    internal var assetFileIds: [String]?

    func toDictionary() -> [String: Any] {

        var dict: [String: Any] = [:]
        dict["context"] = playbackContextType.rawValue
        dict["mediaProtocols"] = protocls
        if let fileIds = self.assetFileIds {
            dict["assetFileIds"] = fileIds.joined(separator: ",")
        }
        return dict
    }
}
