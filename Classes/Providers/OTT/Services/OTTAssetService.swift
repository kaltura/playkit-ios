//
//  Asset.swift
//  Pods
//
//  Created by Admin on 13/11/2016.
//
//

import UIKit
import SwiftyJSON



public enum AssetType: String {
    case media = "media"
    case epg = "epg"
}


internal class OTTAssetService {

    internal static func get(baseURL: String, ks: String,assetId: String, type: AssetType) -> OTTRequestBuilder? {
        
        if let request: OTTRequestBuilder = OTTRequestBuilder(url: baseURL, service: "asset", action: "get") {
            request
            .setBody(key: "id", value: JSON(assetId))
            .setBody(key: "ks", value: JSON(ks))
            .setBody(key: "assetReferenceType", value: JSON(type.rawValue))
            .setBody(key: "type", value: JSON(type.rawValue))
            .setBody(key: "with", value: JSON([["type":"files","objectType":"KalturaCatalogWithHolder"]]))
            return request
        }else{
            return nil
        }
    }
}



