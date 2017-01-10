//
//  OVPUserService.swift
//  Pods
//
//  Created by Rivka Peleg on 29/12/2016.
//
//

import UIKit
import SwiftyJSON

class OVPUserService {

    internal static func loginByLoginId(baseURL: String,
                                        loginId: String,
                                        password: String,
                                        partnerId: Int64) -> KalturaRequestBuilder? {
        
        if let request: KalturaRequestBuilder = KalturaRequestBuilder(url: baseURL,
                                                                      service: "user",
                                                                      action: "loginByLoginId") {
            request.setBody(key: "loginId", value: JSON(loginId))
                .setBody(key: "password", value: JSON(password))
                .setBody(key: "partnerId", value: JSON(partnerId))
            return request
        }else{
            return nil
        }
    }

}
