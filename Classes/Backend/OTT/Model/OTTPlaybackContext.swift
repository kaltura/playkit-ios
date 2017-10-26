// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import Foundation
import SwiftyJSON

public class OTTPlaybackContext: OTTBaseObject {

    var sources: [OTTPlaybackSource] = []
    var actions: [OTTRuleAction] = []
    var messages: [OTTAccessControlMessage] = []

    public required init?(json: Any) {
        let jsonObject = JSON(json)
        jsonObject["sources"].array?.forEach { (source: JSON) in
            if let source = OTTPlaybackSource(json: source.object) {
                sources.append(source)
            }
        }
        
        jsonObject["actions"].array?.forEach { (action: JSON) in
            if let action = OTTRuleAction(json: action.object) {
                actions.append(action)
            }
        }
        
        jsonObject["messages"].array?.forEach { (message: JSON) in
            if let message = OTTAccessControlMessage(json: message.object) {
                messages.append(message)
            }
        }
    }
    
    func hasErrorMessage() -> OTTAccessControlMessage? {
        
        for message in self.messages {
            if (message.code != "OK"){
                return message
            }
        }
        
        return nil
    }
    
    func hasBlockAction() -> OTTRuleAction? {
        
        for action in self.actions {
            if (action.type == .block){
                return action
            }
        }
        
        return nil
    }
}
