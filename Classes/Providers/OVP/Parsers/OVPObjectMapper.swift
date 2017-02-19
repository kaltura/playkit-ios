//
//  ObjectMapper.swift
//  Pods
//
//  Created by Rivka Peleg on 24/11/2016.
//
//

import UIKit
import SwiftyJSON


class OVPObjectMapper: NSObject {
    
    static let classNameKey = "objectType"
    static let errorKey = "objectType"
    
    static func classByJsonObject(json:Any?) -> OVPBaseObject.Type? {
        
        let jsonObject = JSON(json)
        let className = jsonObject[classNameKey].string
        if let name = className{
            switch name {
            case "KalturaMediaEntry":
                return OVPEntry.self
            case "KalturaPlaybackContext":
                return OVPPlaybackContext.self
            case "KalturaAPIException":
                return OVPError.self
            case "KalturaStartWidgetSessionResponse":
                return OVPStartWidgetSessionResponse.self
            case "KalturaMetadata":
                return OVPMetadata.self
            default:
                return nil
            }
        }
        return nil
        
    }
    
    
    
    
    
    
    
}
    
    
    
    
  

