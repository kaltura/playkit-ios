//
//  OTTMediaFile.swift
//  PlayKit
//
//  Created by Nilit Danan on 8/20/18.
//

import Foundation
import SwiftyJSON

class OTTMediaFile: OTTBaseObject {
    
    var id: Int?
    var assetId: Int?
    var duration: Int?
    var url: String?
    var type: String?
    
    let idKey = "id"
    let assetIdKey = "assetId"
    let durationKey = "duration"
    let urlKey = "url"
    let typeKey = "type"
    
    required init?(json: Any) {
        let jsonObj: JSON = JSON(json)
        
        self.id = jsonObj[idKey].int
        self.assetId = jsonObj[assetIdKey].int
        self.duration = jsonObj[durationKey].int
        self.url = jsonObj[urlKey].string
        self.type = jsonObj[typeKey].string
    }
}
