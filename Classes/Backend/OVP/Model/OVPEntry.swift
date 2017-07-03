// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license,
// unless a different license for a particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

//
//  OVPEntry.swift
//  Pods
//
//  Created by Rivka Peleg on 28/11/2016.
//
//

import UIKit
import SwiftyJSON

class OVPEntry: OVPBaseObject {
    
    var id: String
    var dataURL: URL?
    var mediaType: Int?
    var flavorParamsIds: String?
    var duration: TimeInterval = 0
    var name: String?
    var type: Int?
    
    
    let idKey = "id"
    let dataURLKey = "dataUrl"
    let mediaTypeKey = "mediaType"
    let flavorParamsIdsKey = "flavorParamsIds"
    let durationKey = "duration"
    let nameKey = "name"
    let typeKey = "type"
    
    required init?(json: Any) {
        
        let jsonObject = JSON(json)
        guard let id = jsonObject[idKey].string else {
            return nil
        }
        
        self.id = id
        
        if let url = jsonObject[dataURLKey].string{
            let dataURL = URL(string: url)
            self.dataURL = dataURL
            
        }
        
        self.mediaType = jsonObject[mediaTypeKey].int
        self.flavorParamsIds = jsonObject[flavorParamsIdsKey].string
        self.duration = jsonObject[durationKey].double ?? 0
        self.name = jsonObject[nameKey].string
        self.type = jsonObject[typeKey].int
        
    }
}
