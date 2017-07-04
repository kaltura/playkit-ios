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

class OVPFlavorAsset: OVPBaseObject {

    
    
    var id: String
    var tags: String?
    var fileExt: String?
    var paramsId: Int
    
    let idKey = "id"
    let tagsKey = "tags"
    let fileExtKey = "fileExt"
    let paramsIdKey = "flavorParamsId"
    
    required init?(json: Any) {
     
        let jsonObject = JSON(json)
        if let id = jsonObject[idKey].string, let paramID = jsonObject[paramsIdKey].int {
            self.id = id
            self.paramsId = paramID
            
        }else{
            return nil
        }
        
        
        self.tags = jsonObject[tagsKey].string
        self.fileExt = jsonObject[fileExtKey].string
        
        
    }
}
