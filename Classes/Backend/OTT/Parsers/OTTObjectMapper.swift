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

class OTTObjectMapper: NSObject {

    static let classNameKey = "objectType"
    static let errorKey = "error"

    static func classByJsonObject(json: Any?) -> OTTBaseObject.Type? {
        guard let js = json else { return nil }
        let jsonObject = JSON(js)
        let className = jsonObject[classNameKey].string

        if let name = className {
            switch name {
            case "KalturaPlaybackSource":
                return OTTPlaybackSource.self
            case "KalturaPlaybackContext":
                return OTTPlaybackContext.self
            default:
                return nil
            }
        } else {
            if jsonObject[errorKey].dictionary != nil {
                return OTTError.self
            } else {
                return nil
            }
        }
    }
}
