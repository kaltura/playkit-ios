//
//  OTTUser.swift
//  Pods
//
//  Created by Admin on 17/11/2016.
//
//

import UIKit
import SwiftyJSON

internal class OTTLoginSession: OTTBaseObject {
    
    internal var ks: String?
    internal var refreshToken: String?
    
    private let resultKey = "result"
    private let sessionKey = "loginSession"
    private let ksKey = "ks"
    private let refreshTokenKey = "refreshToken"
    
    required init(json:Any) {
        
        let loginJsonResponse = JSON(json)
        let sessionJson = loginJsonResponse[resultKey][sessionKey]
        self.ks = sessionJson[ksKey].string
        self.refreshToken = sessionJson[refreshTokenKey].string
        
    }
}
