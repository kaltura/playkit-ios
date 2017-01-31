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
