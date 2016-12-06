//
//  OTTSession.swift
//  Pods
//
//  Created by Rivka Peleg on 24/11/2016.
//
//

import UIKit
import SwiftyJSON


class OTTSession: OTTBaseObject {

    var tokenExpiration: Date?
    
    let tokenExpirationKey = "expiry"
    
    required init?(json: Any) {
        let jsonObject = JSON(json)
        if let time = jsonObject[tokenExpirationKey].number?.doubleValue{
          self.tokenExpiration =  Date.init(timeIntervalSince1970:time)
        }

    }
}
