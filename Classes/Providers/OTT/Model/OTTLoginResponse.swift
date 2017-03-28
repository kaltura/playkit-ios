//
//  OTTUser.swift
//  Pods
//
//  Created by Admin on 17/11/2016.
//
//

import UIKit
import SwiftyJSON

internal class OTTLoginResponse: OTTBaseObject {

    internal var loginSession: OTTLoginSession?

    private let sessionKey = "loginSession"

    required init(json:Any) {

        let loginJsonResponse = JSON(json)
        let sessionJson = loginJsonResponse[sessionKey]
        self.loginSession = OTTLoginSession(json: sessionJson.object)

    }
}
