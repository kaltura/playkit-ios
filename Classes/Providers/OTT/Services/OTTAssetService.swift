//
//  Asset.swift
//  Pods
//
//  Created by Admin on 13/11/2016.
//
//

import UIKit
import SwiftyJSON

@objc public enum AssetType: Int {
    case media
    case epg
    case unknown
    
    var asString: String {
        switch self {
        case .media: return "media"
        case .epg: return "epg"
        case .unknown: return ""
        }
    }
}

class OTTAssetService {

    static func get(baseURL: String, ks: String, assetId: String, type: AssetType) -> KalturaRequestBuilder? {
        
        if let request: KalturaRequestBuilder = KalturaRequestBuilder(url: baseURL, service: "asset", action: "get") {
            request
            .setBody(key: "id", value: JSON(assetId))
            .setBody(key: "ks", value: JSON(ks))
            .setBody(key: "assetReferenceType", value: JSON(type.asString))
            .setBody(key: "type", value: JSON(type.rawValue))
            .setBody(key: "with", value: JSON([["type": "files","objectType": "KalturaCatalogWithHolder"]]))
            return request
        } else {
            return nil
        }
    }
}



