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

//"drm": [{
//"scheme": "FairPlay",
//"certificate": "base64-encoded-certificate",
//"licenseURL": "https://udrm.kaltura.com/..."
//}]

class OVPDRM: OVPBaseObject {

    var scheme: String?
    var licenseURL: String?
    var certificate: String?
    
    private let schemeKey = "scheme"
    private let licenseURLKey = "licenseURL"
    private let certificateKey = "certificate"
    
    required init?(json: Any) {
        
        let jsonObject = JSON(json)
        self.scheme = jsonObject[schemeKey].string
        self.licenseURL = jsonObject[licenseURLKey].string
        self.certificate = jsonObject[certificateKey].string
    
    }
}
