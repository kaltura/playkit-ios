// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

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
