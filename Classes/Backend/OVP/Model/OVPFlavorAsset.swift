//
//  FlavorAsset.swift
//  Pods
//
//  Created by Rivka Peleg on 28/11/2016.
//
//

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
