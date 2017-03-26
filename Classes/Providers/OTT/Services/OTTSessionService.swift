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

    internal static func get(baseURL: String, ks: String) -> KalturaRequestBuilder? {

        if let request = KalturaRequestBuilder(url: baseURL, service: "session", action: "get") {
            request
                .setBody(key: "ks", value: JSON(ks))
            return request
        } else {
            return nil
        }

    }

    internal static func switchUser(baseURL: String, ks: String, userId: String) -> KalturaRequestBuilder? {

        if let request = KalturaRequestBuilder(url: baseURL, service: "session", action: "switchUser") {
            request
                .setBody(key: "ks", value: JSON(ks))
                .setBody(key: "userIdToSwitch", value: JSON(userId))
            return request
        } else {
            return nil
        }

    }

}
