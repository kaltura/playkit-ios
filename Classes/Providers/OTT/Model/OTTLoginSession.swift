//
//  OTTLoginSession.swift
//  Pods
//
//  Created by Rivka Peleg on 04/12/2016.
//
//

import UIKit
import SwiftyJSON

class OTTLoginSession: OTTBaseObject {

    internal var ks: String?
    internal var refreshToken: String?

    private let ksKey = "ks"
    private let refreshTokenKey = "refreshToken"

    required init(json:Any) {

        let jsonObject = JSON(json)
        self.ks = jsonObject[ksKey].string
        self.refreshToken = jsonObject[refreshTokenKey].string

    }
}
