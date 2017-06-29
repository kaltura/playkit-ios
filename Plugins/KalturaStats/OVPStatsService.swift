//
//  OTTStatsService.swift
//  Pods
//
//  Created by Oded Klein on 07/12/2016.
//
//

import UIKit
import SwiftyJSON
import KalturaNetKit

internal class OVPStatsService {

    static func get(config: KalturaStatsPluginConfig, eventType: Int, clientVer: String, duration: Float, sessionId: String, position: Int32, widgetId: String, isSeek: Bool, referrer: String = "") -> KalturaRequestBuilder? {
        
        return get(
            baseURL: config.baseUrl,
            partnerId: "\(config.partnerId)",
            eventType: eventType,
            clientVer: PlayKitManager.clientTag,
            duration: duration,
            sessionId: sessionId,
            position: position,
            uiConfId: config.uiconfId,
            entryId: config.entryId,
            widgetId: widgetId,
            isSeek: isSeek,
            contextId: config.contextId,
            appId: config.applicationId,
            userId: config.userId
        )
    }
    
    static func get(baseURL: String, partnerId: String, eventType: Int, clientVer: String, duration: Float, sessionId: String, position: Int32, uiConfId: Int, entryId: String, widgetId: String, isSeek: Bool, referrer: String = "", contextId: Int, appId: String?, userId: String?) -> KalturaRequestBuilder? {
        
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
                .setParam(key: "event:eventTimeStamp", value: "\(Date().timeIntervalSince1970)")
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
            
            if contextId > 0 {
                request.setParam(key: "event:contextId", value: "\(contextId)")
            }
            if let applicationId = appId, applicationId != "" {
                request.setParam(key: "event:applicationId", value: applicationId)
            }
            if let userId = userId, userId != "" {
                request.setParam(key: "event:userId", value: userId)
            }
            
            return request
        } else {
            return nil
        }
    }

}
