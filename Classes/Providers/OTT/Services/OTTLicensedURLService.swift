//
//  LicensedURLService.swift
//  Pods
//
//  Created by Admin on 21/11/2016.
//
//

import UIKit
import SwiftyJSON

class OTTLicensedURLService: NSObject {

    internal static func get(baseURL: String, ks: String, fileId: String, fileBaseURL: String) -> KalturaRequestBuilder? {

            if let request: KalturaRequestBuilder = KalturaRequestBuilder(url: baseURL, service: "licensedUrl", action: "get") {
                request.setBody(key:"ks", value: JSON(ks))
                .setBody(key: "content_id", value: JSON(fileId))
                .setBody(key: "base_url", value: JSON(fileBaseURL))
                return request
            } else {
                return nil
            }
        }

}
