//
//  KalturaRuleAction.swift
//  Pods
//
//  Created by Rivka Peleg on 05/07/2017.
//
//

import Foundation
import SwiftyJSON

enum KalturaRuleActionType: String {
    case block = "BLOCK"
}

class KalturaRuleAction: KalturaBaseObject {
    
    var type: KalturaRuleActionType? = nil
    
    required init?(json: Any) {
        let jsonDict = JSON(json)
        if let type = jsonDict["type"].string {
            self.type = KalturaRuleActionType(rawValue: type)
        }
    }
}
