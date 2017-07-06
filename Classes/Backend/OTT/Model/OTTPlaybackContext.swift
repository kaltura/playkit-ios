// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license,
// unless a different license for a particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import Foundation
import SwiftyJSON

class OTTPlaybackContext: OTTBaseObject {

    var sources: [OTTPlaybackSource] = []
    var actions: [KalturaRuleAction] = []
    var messages: [KalturaAccessControlMessage] = []

    required init?(json: Any) {
        let jsonObject = JSON(json)
        jsonObject["sources"].array?.forEach { (source: JSON) in
            if let source = OTTPlaybackSource(json: source.object) {
                sources.append(source)
            }
        }
        
        jsonObject["actions"].array?.forEach { (action: JSON) in
            if let action = KalturaRuleAction(json: action.object) {
                actions.append(action)
            }
        }
        
        jsonObject["messages"].array?.forEach { (message: JSON) in
            if let message = KalturaAccessControlMessage(json: message.object) {
                messages.append(message)
            }
        }
    }
    
    func hasErrorMessage() -> KalturaAccessControlMessage? {
        
        for message in self.messages {
            if (message.code != "OK"){
                return message
            }
        }
        
        return nil
    }
    
    func hasBlockAction() -> KalturaRuleAction? {
        
        for action in self.actions {
            if (action.type == .ottBlock){
                return action
            }
        }
        
        return nil
    }
}
