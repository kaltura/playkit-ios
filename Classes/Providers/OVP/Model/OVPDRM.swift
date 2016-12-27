//
//  OVPDRM.swift
//  Pods
//
//  Created by Rivka Peleg on 29/11/2016.
//
//

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
    
    let schemeKey = "scheme"
    let licenseURLKey = "licenseURL"
    
    required init?(json: Any) {
        
        let jsonObject = JSON(json)
        self.scheme = jsonObject[schemeKey].string
        self.licenseURL = jsonObject[licenseURLKey].string
        
    }
}
