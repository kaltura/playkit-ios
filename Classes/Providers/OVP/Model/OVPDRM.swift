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
    var certificate: String?
    var licenseURL: URL?
    
    let schemeKey = "scheme"
    let certificateKey = "certificate"
    let licenseURLKey = "licenseURL"
    
    required init?(json: Any) {
        
        let jsonObject = JSON(json)
        self.scheme = jsonObject[schemeKey].string
        self.certificate = jsonObject[certificateKey].string
        self.licenseURL = jsonObject[licenseURLKey].URL
        
    }
}
