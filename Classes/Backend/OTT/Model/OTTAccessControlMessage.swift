//
//  OTTAccessControlMessage.swift
//  Pods
//
//  Created by Eliza Sapir on 06/07/2017.
//
//

import Foundation
import SwiftyJSON


class OTTAccessControlMessage: OTTBaseObject {
    var message: String? = nil
    var code: String? = nil
    
    required init?(json: Any) {
        let jsonDict = JSON(json)
        self.message = jsonDict["message"].string
        self.code = jsonDict["code"].string
    }
}
