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
//  OVPRuleAction.swift
//  Pods
//
//  Created by Eliza Sapir on 06/07/2017.
//
//

import Foundation
import SwiftyJSON

enum OVPRuleActionType: Int {
    case block = 1
    case preview = 2
}

class OVPRuleAction: KalturaBaseObject {
    
    var type: OVPRuleActionType? = nil
    
    required init?(json: Any) {
        let jsonDict = JSON(json)
        if let type = jsonDict["type"].int {
            self.type = OVPRuleActionType(rawValue: type)
        }
    }
}
