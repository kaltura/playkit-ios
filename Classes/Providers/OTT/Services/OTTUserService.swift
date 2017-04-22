//
//  OTTUserService.swift
//  Pods
//
//  Created by Admin on 13/11/2016.
//
//

import UIKit
import SwiftyJSON
import KalturaNetKit

class OTTUserService: NSObject {

    internal static func anonymousLogin(baseURL: String, partnerId: Int64, udid: String? = nil) -> KalturaRequestBuilder? {
        if let request = KalturaRequestBuilder(url: baseURL, service: "ottUser", action: "anonymousLogin") {
            request.setBody(key: "partnerId", value: JSON(NSNumber.init(value: partnerId)))

            if let deviceId = udid {
                request.setBody(key: "udid", value: JSON(deviceId))
            }
            return request
        }
        return nil
    }

}
