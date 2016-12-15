//
//  MediaMarkService.swift
//  Pods
//
//  Created by Oded Klein on 12/12/2016.
//
//

import UIKit
import SwiftyJSON

internal class MediaMarkService {

    internal static func sendTVPAPIEVent(baseURL: String,
                                         initObj: JSON?,
                                         eventType: String,
                                         currentTime: Float,
                                         assetId: String,
                                         fileId: String) -> KalturaRequestBuilder? {
        
        if let request: KalturaRequestBuilder = KalturaRequestBuilder(url: baseURL, service: nil, action: nil) {
            request
                .set(method: "POST")
                
            if let obj = initObj {
                request.set(jsonBody: obj)
            }
            request
                .setBody(key: "iFileID", value: JSON(fileId))
                .setBody(key: "iMediaID", value: JSON(assetId))
                .setBody(key: "iLocation", value: JSON(currentTime))
                .setBody(key: "mediaType", value: JSON(0))
            if eventType != "hit" {
                request.setBody(key: "Action", value: JSON(eventType))
            }
            return request
        }else{
            return nil
        }

    }

    private static func createBookmark(eventType: String, position: Float, assetId: String, fileId: String) -> JSON {
        var json: JSON = JSON.init(["objectType": "KalturaBookmark"])
        json["type"] = JSON("media")
        json["id"] = JSON(assetId)
        json["position"] = JSON(position)
        json["playerData"] = JSON.init(["action": JSON(eventType), "objectType": JSON("KalturaBookmarkPlayerData"), "fileId": JSON(fileId)])

        
        return json
    }
}
