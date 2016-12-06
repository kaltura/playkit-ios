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
    var format: String?
    var protocols: [String]?
    var flavors: [String]?
    var url: URL?
    var drm: [OVPDRM]?
    
    
    let deliveryProfileIdKey = "deliveryProfileId"
    let formatKey = "format"
    let protocolsKey = "protocols"
    let flavorsKey = "flavors"
    let urlKey = "url"
    let drmKey = "drm"
    
    
    required init?(json: Any) {
        
        let jsonObject = JSON(json)
        
        guard let id =  jsonObject[deliveryProfileIdKey].int64 else {
            return nil
        }
        
        self.deliveryProfileId = id
        self.format = jsonObject[formatKey].string
        if let array = jsonObject[protocolsKey].arrayObject as? [String]?{
            self.protocols = array
        }
        
        if let array = jsonObject[flavorsKey].arrayObject as? [String]?{
            self.flavors = array
        }
        
        if let url = jsonObject[urlKey].URL{
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
