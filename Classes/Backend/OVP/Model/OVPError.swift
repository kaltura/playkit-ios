// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================


//{
//    "code": "INVALID_KS",
//    "message": "Invalid KS \"djJ8MjIw5MXyl39EU-cKOiXxMdCjh0ieKyUfgME8r5cEvz4Pwa-UkKf8-qMh2xcMOrVb6Ccq5cdqX_jE5EhlnpwbWAOl2DHzmMOmozMggZ59tzTbYeg646gkW5tDKv5ZQgqd5IvjVMRE=\", Error \"-1,INVALID_STR\"",
//    "objectType": "KalturaAPIException",
//    "args": {
//        "KSID": "djJ8MjIw5MXyl39EU-cKOiXxMdCjh0ieKyUfgME8r5cEvz4Pwa-UkKf8-qMh2xcMOrVb6Ccq5cdqX_jE5EhlnpwbWAOl2DHzmMOmozMggZ59tzTbYeg646gkW5tDKv5ZQgqd5IvjVMRE=",
//        "ERR_CODE": "-1",
//        "ERR_DESC": "INVALID_STR"
//    }
//},

import UIKit
import SwiftyJSON

class OVPError: OVPBaseObject {
    
    var code: String?
    var message: String?
    var args:[String: Any]?
    
    
    var codeKey = "code"
    var messageKey = "message"
    var argsKey = "args"
    
    
    
    required init?(json: Any) {
        
        let jsonObject = JSON(json)
        self.code = jsonObject[codeKey].string
        self.message = jsonObject[messageKey].string
        if let args = jsonObject[argsKey].object as? [String:Any]
        {
           self.args = args
        }
        
        
    }
    

}
