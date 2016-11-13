//
//  OTTUserService.swift
//  Pods
//
//  Created by Admin on 13/11/2016.
//
//

import UIKit
import SwiftyJSON

public class OTTUserService: NSObject {

    
   public static func login(sessionProvider:SessionProvider,username:String,password:String) -> RestRequestBuilder? {
        
        if let request = RestRequestBuilder(baseURL: sessionProvider.serverURL, service: "ottUser", action: "login") {
                request
                    .setBody(key: "username", value: JSON(username))
                    .setBody(key: "password", value: JSON(password))
                    .setBody(key: "partnerId", value: JSON(NSNumber.init(value: sessionProvider.partnerId)))
            
                return request
        }else{
            return nil
        }
    }
}
