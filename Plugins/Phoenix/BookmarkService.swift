//
//  BookmarkService.swift
//  Pods
//
//  Created by Oded Klein on 12/12/2016.
//
//

import UIKit
import SwiftyJSON

internal class BookmarkService {

    internal static func actionAdd(baseURL: String,
                                   partnerId: Int,
                                   ks: String,
                                   eventType: String,
                                   currentTime: Float,
                                   assetId: String,
                                   fileId: String) -> KalturaRequestBuilder? {
        
        if ks == "" {
            
            if let request = KalturaRequestBuilder(url: baseURL, service: nil, action: nil) {
                request
                    .setBody(key: "ks", value: JSON("{1:result:ks}"))
                    .setBody(key: "bookmark", value: createBookmark(eventType: eventType, position: currentTime, assetId: assetId, fileId: fileId))
                    .setBody(key: "service", value: JSON("bookmark"))
                    .setBody(key: "action", value: JSON("add"))
                    .set(method: "POST")

            }
            
            return nil
        }
        
        if let request: KalturaRequestBuilder = KalturaRequestBuilder(url: baseURL, service: "bookmark", action: "add") {
            request
                .setOTTBasicParams()
                .set(method: "POST")
                .setBody(key: "ks", value: JSON(ks))
                .setBody(key: "bookmark", value: createBookmark(eventType: eventType, position: currentTime, assetId: assetId, fileId: fileId))
            return request
        }else{
            return nil
        }

    }

    private static func createBookmark(eventType: String, position: Float, assetId: String, fileId: String) -> JSON {
        var json: JSON = JSON.init(["objectType": "KalturaBookmark"])
        json["type"] = JSON("media")
        //json["id"] = JSON(assetId)
        json["position"] = JSON(position)
        json["playerData"] = JSON.init(["action": JSON(eventType), "objectType": JSON("KalturaBookmarkPlayerData"), "fileId": JSON(fileId)])

        
        return json
    }
}
