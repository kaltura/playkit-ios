// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import UIKit
import SwiftyJSON

//{
//    "partnerId": 1851571,
//    "ks": "djJ8MTg1MTU3MXxpaGILkzBCPpdG6oGTMOBdCMcLCX8Cnl2BNlJVGZ6uqoz6fknXXha6b-j_ljU1151redfcbuR2Mt9fNoH7h52x6fyp9aztK4YrR0nsiHE9PQ==",
//    "userId": 0,
//    "objectType": "KalturaStartWidgetSessionResponse"
//}

class OVPStartWidgetSessionResponse: OVPBaseObject {

    let ks: String
    private let ksKey = "ks"
    
    required init?(json:Any){
        let json = JSON(json)
        if let ks = json[self.ksKey].string {
            self.ks = ks
        }else{
            return nil
        }
    }

}
