//
//  ...swift
//  Pods
//
//  Created by Rivka Peleg on 29/11/2016.
//
//

import UIKit
import SwiftyJSON

class OVPSource: OVPBaseObject {
    
    var deliveryProfileId: Int64
    var format: String
    var protocols: [String]?
    var flavors: [String]?
    var url: URL?
    var drm: [OVPDRM]?
    
    
    let deliveryProfileIdKey = "deliveryProfileId"
    let formatKey = "format"
    let protocolsKey = "protocols"
    let flavorsKey = "flavorIds"
    let urlKey = "url"
    let drmKey = "drm"
    
    
    required init?(json: Any) {
        
        let jsonObject = JSON(json)
        
        guard let id =  jsonObject[deliveryProfileIdKey].int64,
            let format = jsonObject[formatKey].string
            else {
                return nil
        }
        
        self.deliveryProfileId = id
        self.format = format
        if let protocols = jsonObject[protocolsKey].string{
            self.protocols = protocols.components(separatedBy: ",")
        }
        
        if let flavors = jsonObject[flavorsKey].string {
            self.flavors = flavors.components(separatedBy: ",")
        }
        
        if let url = jsonObject[urlKey].url{
            self.url = url
        }
        
        if let drmArray = jsonObject[drmKey].array{
            
            var drmObjects: [OVPDRM] = [OVPDRM]()
            for drmJSON in drmArray{
                if let object = OVPDRM(json: drmJSON.object){
                    drmObjects.append(object)
                }
                
            }
            self.drm = drmObjects
        }
        
    }
    
}
