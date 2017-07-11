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
//  OTTRuleAction.swift
//  Pods
//
//  Created by Eliza Sapir on 06/07/2017.
//
//

import Foundation
import SwiftyJSON

enum OTTRuleActionType: String {
    case block = "BLOCK"
}

class OTTRuleAction: KalturaBaseObject {
    
    var type: OTTRuleActionType? = nil
    
    required init?(json: Any) {
        let jsonDict = JSON(json)
        if let type = jsonDict["type"].string {
            self.type = OTTRuleActionType(rawValue: type)
        }
    }
}
