//
//  OTTStatsService.swift
//  Pods
//
//  Created by Oded Klein on 07/12/2016.
//
//

import UIKit
import SwiftyJSON

internal class OVPStatsService {

    internal static func get(baseURL: String, partnerId: String, eventType: Int, clientVer: String, duration: Float,sessionId: String, position: Int32, uiConfId: Int, entryId: String, widgetId: String, isSeek: Bool, referrer: String = "") -> KalturaRequestBuilder? {
        
        if let request: KalturaRequestBuilder = KalturaRequestBuilder(url: baseURL, service: nil, action: nil) {
            request
                .setParam(key: "clientTag", value: "kwidget:v\(clientVer)")
                .setParam(key: "service", value: "stats")
                .setParam(key: "apiVersion", value: "3.1")
                .setParam(key: "expiry", value: "86400")
                .setParam(key: "format", value: "1")
                .setParam(key: "ignoreNull", value: "1")
                .setParam(key: "action", value: "collect")
                .setParam(key: "event:eventType", value: "\(eventType)")
                .setParam(key: "event:clientVer", value: "\(clientVer)")
                .setParam(key: "event:currentPoint", value: "\(position)")
                .setParam(key: "event:duration", value: "\(duration)")
                .setParam(key: "event:eventTimeStamp", value: "\(Date().timeIntervalSince1970)") //
                .setParam(key: "event:isFirstInSession", value: "false")
                .setParam(key: "event:objectType", value: "KalturaStatsEvent")
                .setParam(key: "event:partnerId", value: partnerId)
                .setParam(key: "event:sessionId", value: sessionId)
                .setParam(key: "event:uiconfId", value: "\(uiConfId)")
                .setParam(key: "event:seek", value: String(isSeek))
                .setParam(key: "event:entryId", value: entryId)
                .setParam(key: "event:widgetId", value: widgetId)
                .setParam(key: "event:referrer", value: referrer)
            
                .set(method: .get)
            return request
        }else{
            return nil
        }
    }

}
