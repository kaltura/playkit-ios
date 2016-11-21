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


internal extension RequestBuilder {
    
     internal func setClientTag() -> RequestBuilder {
        self.setBody(key: "clientTag", value: "java:16-09-10")
        return self
    }
    
     internal func setApiVersion() -> RequestBuilder {
        self.setBody(key: "apiVersion", value: "3.6.1078.11798")
        return self
    }
    
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
            .setClientTag()
            .setApiVersion()
            
            return request
        }else{
            return nil
        }
    }
}



