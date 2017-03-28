//
//  OTTDrmPlaybackPluginData.swift
//  Pods
//
//  Created by Rivka Peleg on 05/03/2017.
//
//

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
