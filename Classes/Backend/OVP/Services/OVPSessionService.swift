//
//  OVPSessionService.swift
//  Pods
//
//  Created by Rivka Peleg on 29/12/2016.
//
//

import UIKit
import SwiftyJSON
import KalturaNetKit

class OVPSessionService {
        
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
}
