//
//  KalturaAccessControlMessage.swift
//  Pods
//
//  Created by Rivka Peleg on 05/07/2017.
//
//

import Foundation
import SwiftyJSON


class KalturaAccessControlMessage: OTTBaseObject {
    var message: String? = nil
    var code: String? = nil
    
    required init?(json: Any) {
        let jsonDict = JSON(json)
        self.message = jsonDict["message"].string
        self.code = jsonDict["code"].string
    }
    
    
}
