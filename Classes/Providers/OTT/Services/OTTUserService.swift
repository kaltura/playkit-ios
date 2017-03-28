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

    internal static func login(baseURL: String, partnerId: Int64, username: String, password: String, udid: String? = nil) -> KalturaRequestBuilder? {

        if let request = KalturaRequestBuilder(url: baseURL, service: "ottUser", action: "login") {
            request
                .setBody(key: "username", value: JSON(username))
                .setBody(key: "password", value: JSON(password))
                .setBody(key: "partnerId", value: JSON(NSNumber.init(value: partnerId)))

            if let deviceId = udid {
                request.setBody(key: "udid", value: JSON(udid))
            }
            return request
        }

        return nil
    }

    internal static func refreshSession(baseURL: String, refreshToken: String, ks: String, udid: String? = nil) -> KalturaRequestBuilder? {
        if let request = KalturaRequestBuilder(url: baseURL, service: "ottUser", action: "refreshSession") {
            request
                .setBody(key: "refreshToken", value: JSON(refreshToken))
                .setBody(key: "ks", value: JSON(ks))
            if let deviceId = udid {
                request.setBody(key: "udid", value: JSON(udid))
            }
            return request
        }
        return nil
    }

    internal static func anonymousLogin(baseURL: String, partnerId: Int64, udid: String? = nil) -> KalturaRequestBuilder? {
        if let request = KalturaRequestBuilder(url: baseURL, service: "ottUser", action: "anonymousLogin") {
            request.setBody(key: "partnerId", value: JSON(NSNumber.init(value: partnerId)))

            if let deviceId = udid {
                request.setBody(key: "udid", value: JSON(udid))
            }
            return request
        }
        return nil
    }

    internal static func logout(baseURL: String, partnerId: Int64, ks: String, udid: String? = nil) -> KalturaRequestBuilder? {
        if let request = KalturaRequestBuilder(url: baseURL, service: "ottUser", action: "logout") {
            request.setBody(key: "ks", value: JSON(ks))
            request.setBody(key: "partnerId", value: JSON(NSNumber.init(value: partnerId)))

            if let deviceId = udid {
                request.setBody(key: "udid", value: JSON(udid))
            }

            return request
        }
        return nil
    }
}
