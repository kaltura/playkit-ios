//
//  LiveStatsService
//  Pods
//
//  Created by Oded Klein on 07/12/2016.
//
//

import UIKit
import SwiftyJSON

internal class LiveStatsService {

    internal static func sendLiveStatsEvent(baseURL: String,
                                            partnerId: String,
                                            eventType: Int,
                                            eventIndex: Int,
                                            bufferTime: Int32,
                                            bitrate: Int32,
                                            sessionId: String,
                                            startTime: Int32,
                                            entryId: String,
                                            isLive: Bool,
                                            clientVer: String,
                                            deliveryType: String) -> RequestBuilder? {
        
        if let request: RequestBuilder = RequestBuilder(url: baseURL) {
            request
                .setParam(key: "clientTag", value: "kwidget:v\(clientVer)")
                .setParam(key: "service", value: "liveStats")
                .setParam(key: "apiVersion", value: "3.1")
                .setParam(key: "expiry", value: "86400")
                .setParam(key: "format", value: "1")
                .setParam(key: "ignoreNull", value: "1")
                .setParam(key: "action", value: "collect")
                .setParam(key: "event:eventType", value: "\(eventType)")
                .setParam(key: "event:partnerId", value: partnerId)
                .setParam(key: "event:sessionId", value: sessionId)
                .setParam(key: "event:eventIndex", value: "\(eventIndex)")
                .setParam(key: "event:bufferTime", value: "\(bufferTime)")
                .setParam(key: "event:bitrate", value: "\(bitrate)")
                .setParam(key: "event:isLive", value: "\(isLive)")
                .setParam(key: "event:startTime", value: "\(startTime)")
                .setParam(key: "event:entryId", value: entryId)
                .setParam(key: "event:deliveryType", value: deliveryType)
            
                .set(method: .get)
            return request
        }else{
            return nil
        }
    }

}
