// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

//
//  OVPAccessControlMessage.swift
//  Pods
//
//  Created by Eliza Sapir on 06/07/2017.
//
//

import Foundation
import SwiftyJSON


class OVPAccessControlMessage: OVPBaseObject {
    var message: String? = nil
    var code: String? = nil
    
    required init?(json: Any) {
        let jsonDict = JSON(json)
        self.message = jsonDict["message"].string
        self.code = jsonDict["code"].string
    }
}
