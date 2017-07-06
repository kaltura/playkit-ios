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
