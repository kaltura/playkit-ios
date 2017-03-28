//
//  OTTSocialService.swift
//  Pods
//
//  Created by Rivka Peleg on 09/03/2017.
//
//

import Foundation
import SwiftyJSON

@objc public enum KalturaSocialNetwork: Int {
    case facebook

    func stringValue() -> String {
        switch self {
        case .facebook:
            return "FACEBOOK"
        default:
            return ""
        }
    }
}

class OTTSocialService: NSObject {

    internal static func login(baseURL: String, partner: Int, token: String, type: KalturaSocialNetwork, udid: String) -> KalturaRequestBuilder? {

        if let request: KalturaRequestBuilder = KalturaRequestBuilder(url: baseURL, service: "social", action: "login") {
            request
                .setBody(key: "partnerId", value: JSON(partner))
                .setBody(key: "token", value: JSON(token))
                .setBody(key: "type", value: JSON(type.stringValue()))
                .setBody(key: "udid", value:JSON(udid))
            return request
        } else {
            return nil
        }
    }

}
