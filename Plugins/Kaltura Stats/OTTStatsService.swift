//
//  OTTStatsService.swift
//  Pods
//
//  Created by Oded Klein on 07/12/2016.
//
//

import UIKit
import SwiftyJSON

internal class OTTStatsService {

    internal static func get(baseURL: String, partnerId: String, eventType: Int, clientVer: String, duration: Float,
                             sessionId: String, position: Float, uiConfId: Int, entryId: String, widgetId: String, isSeek: Bool, referrer: String = "") -> KalturaRequestBuilder? {
        
        if let request: KalturaRequestBuilder = KalturaRequestBuilder(url: baseURL, service: nil, action: nil) {
            request
                .setBody(key: "service", value: JSON("stats"))
                .setBody(key: "apiVersion", value: JSON("3.1"))
                .setBody(key: "expiry", value: JSON("86400"))
                .setBody(key: "clientTag", value: JSON("kwidget:v\(clientVer)"))
                .setBody(key: "format", value: JSON("1"))
                .setBody(key: "ignoreNull", value: JSON("1"))
                .setBody(key: "action", value: JSON("collect"))
                .setBody(key: "event:eventType", value: JSON(eventType))
                .setBody(key: "event:clientVer", value: JSON(clientVer))
                .setBody(key: "event:currentPoint", value: JSON(position))
                .setBody(key: "event:duration", value: JSON(duration))
                .setBody(key: "event:eventTimeStamp", value: JSON(Date().timeIntervalSince1970)) //
                .setBody(key: "event:isFirstInSession", value: JSON("false"))
                .setBody(key: "event:objectType", value: JSON("KalturaStatsEvent"))
                .setBody(key: "event:partnerId", value: JSON(partnerId))
                .setBody(key: "event:sessionId", value: JSON(sessionId))
                .setBody(key: "event:uiconfId", value: JSON(uiConfId))
                .setBody(key: "event:seek", value: JSON(isSeek))
                .setBody(key: "event:entryId", value: JSON(entryId))
                .setBody(key: "event:widgetId", value: JSON(widgetId))
                .setBody(key: "event:referrer", value: JSON(referrer))
            
                //.setBody(key: "", value: JSON(""))

            return request
        }else{
            return nil
        }
    }

}

/*
 .appendQueryParameter("event:sessionId", sessionId)
 .appendQueryParameter("event:uiconfId", Integer.toString(uiConfId))
 .appendQueryParameter("event:seek", Boolean.toString(isSeek))
 .appendQueryParameter("event:entryId", entryId)
 .appendQueryParameter("event:widgetId", widgetId)

 */
