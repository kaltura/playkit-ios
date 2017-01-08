//
//  OVPSessionService.swift
//  Pods
//
//  Created by Rivka Peleg on 29/12/2016.
//
//

import UIKit
import SwiftyJSON

class OVPSessionService {
    
    internal static func get(baseURL: String,
                             ks: String) -> KalturaRequestBuilder? {
        
        if let request: KalturaRequestBuilder = KalturaRequestBuilder(url: baseURL,
                                                                      service: "session",
                                                                      action: "get") {
            request.setBody(key: "ks", value: JSON(ks))
            return request
        }else{
            return nil
        }
    }
    
    internal static func startWidgetSession(baseURL: String,
                                            partnerId: Int64 )  -> KalturaRequestBuilder? {
        
        if let request: KalturaRequestBuilder = KalturaRequestBuilder(url: baseURL,
                                                                      service: "session",
                                                                      action: "startWidgetSession") {
            
            request.setBody(key: "widgetId", value: JSON("_" + String(partnerId)))
            return request
        }else{
            return nil
        }
        
    }
                                            
    
    
    
//    .service("session")
//    .action("startWidgetSession")
//    .method("POST")
//    .url(baseUrl)
//    .tag("session-startWidget")
//    .params(params);
}
