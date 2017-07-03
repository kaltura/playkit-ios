// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license,
// unless a different license for a particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import UIKit
import SwiftyJSON
import KalturaNetKit

class MediaMarkService {

    static func sendTVPAPIEVent(baseURL: String,
                                         initObj: [String: Any],
                                         eventType: String,
                                         currentTime: Int32,
                                         assetId: String,
                                         fileId: String) -> RequestBuilder? {
        
        if let request: RequestBuilder = RequestBuilder(url: baseURL) {
            request
                .set(method: .post)
                .setBody(key: "initObj", value: JSON(initObj))
                .setBody(key: "iFileID", value: JSON(fileId))
                .setBody(key: "iMediaID", value: JSON(assetId))
                .setBody(key: "iLocation", value: JSON(currentTime))
                .setBody(key: "mediaType", value: JSON(0))
            if eventType != "hit" {
                request.setBody(key: "Action", value: JSON(eventType))
            }
            return request
        } else {
            return nil
        }
    }
}
