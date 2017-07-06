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
