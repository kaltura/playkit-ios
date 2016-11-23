//
//  OTTSessionService.swift
//  Pods
//
//  Created by Admin on 17/11/2016.
//
//

import UIKit
import SwiftyJSON

internal class OTTSessionService: NSObject {

    
    internal static func get(baseURL:String,ks:String) -> OTTRequestBuilder? {
        
        if let request = OTTRequestBuilder(url: baseURL, service: "session", action: "get") {
            request
                .setBody(key: "ks", value: JSON(ks))
            return request
        }else{
            return nil
        }

    }
    
}
