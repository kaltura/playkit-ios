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

class OVPPlaybackContext: OVPBaseObject {
    
    var flavorAssets: [OVPFlavorAsset]? = nil
    var sources: [OVPSource]?
    let flavorAssetsKey = "flavorAssets"
    let sourcesKey = "sources"
    var actions: [OVPRuleAction] = []
    var messages: [OVPAccessControlMessage] = []
    
    required internal init?(json: Any)
    {
        let jsonObject = JSON(json)
        let flavorAssetsJson = jsonObject[flavorAssetsKey].array
        
        self.flavorAssets = [OVPFlavorAsset]()
        flavorAssetsJson?.forEach({ (flavorAssetJson: JSON) in
            if let flavorAsset = OVPFlavorAsset(json: flavorAssetJson.object){
                self.flavorAssets?.append(flavorAsset)
            }
        })
        
        let sources = jsonObject[sourcesKey].array
        self.sources = [OVPSource]()
        sources?.forEach({ (sourceJson:JSON) in
            if let source = OVPSource(json: sourceJson.object){
                self.sources?.append(source)
            }
        })
        
        jsonObject["actions"].array?.forEach { (action: JSON) in
            if let action = OVPRuleAction(json: action.object) {
                actions.append(action)
            }
        }
        
        jsonObject["messages"].array?.forEach { (message: JSON) in
            if let message = OVPAccessControlMessage(json: message.object) {
                messages.append(message)
            }
        }
    }
    
    func hasErrorMessage() -> OVPAccessControlMessage? {
        
        for message in self.messages {
            if (message.code != "OK"){
                return message
            }
        }
        
        return nil
    }
    
    func hasBlockAction() -> OVPRuleAction? {
        
        for action in self.actions {
            if (action.type == .block){
                return action
            }
        }
        
        return nil
    }
}
