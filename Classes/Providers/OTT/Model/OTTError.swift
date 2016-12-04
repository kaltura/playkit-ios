//
//  OTTError.swift
//  Pods
//
//  Created by Rivka Peleg on 24/11/2016.
//
//

import UIKit
import SwiftyJSON



class OTTError: OTTBaseObject {
    
    var message: String?
    var code: String?
    
    let errorKey = "error"
    let messageKey = "message"
    let codeKey = "code"
    
    
    required init?(json: Any) {
        
        let jsonObj: JSON = JSON(json)
        self.message = jsonObj[errorKey][messageKey].string
        self.code = jsonObj[errorKey][codeKey].string
    }
    
    init() {
        
    }
    
}
