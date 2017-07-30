// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import Foundation
import SwiftyJSON

class OTTDrmData: OTTBaseObject {

    var scheme: String
    var licenseURL: String
    var certificate: String?

    required init?(json: Any) {
        let jsonObject = JSON(json)

        guard  let scheme = jsonObject["scheme"].string,
               let licenseURL = jsonObject["licenseURL"].string
        else {
            return nil
        }

        self.scheme = scheme
        self.licenseURL = licenseURL
        self.certificate = jsonObject["certificate"].string
    }
}
