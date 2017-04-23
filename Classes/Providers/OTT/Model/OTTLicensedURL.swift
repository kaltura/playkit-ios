//
//  OTTLicensedURL.swift
//  Pods
//
//  Created by Admin on 21/11/2016.
//
//

import UIKit
import SwiftyJSON

internal class OTTLicensedURL: OTTBaseObject {

    internal var mainuRL: String

    private let mainuRLKey = "mainUrl"
    private let resultKey = "result"

    internal required init?(json:Any) {

        let licensedURLJson = JSON(json)
        guard let url = licensedURLJson[resultKey][mainuRLKey].string else {
            return nil
        }

        self.mainuRL = url

    }
}
