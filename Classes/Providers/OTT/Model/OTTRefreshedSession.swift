//
//  OTTRefreshedSession.swift
//  Pods
//
//  Created by Rivka Peleg on 24/11/2016.
//
//

import UIKit
import SwiftyJSON

class OTTRefreshedSession: OTTBaseObject {

    var ks: String?
    var refreshToken: String?

    private let ksKey = "ks"
    private let refreshTokenKey = "refreshToken"

    required init?(json: Any) {

        let json = JSON(json)
        self.ks = json[ksKey].string
        self.refreshToken = json[refreshTokenKey].string

    }
}
