//
//  ObjectMapper.swift
//  Pods
//
//  Created by Rivka Peleg on 24/11/2016.
//
//

import UIKit
import SwiftyJSON



class OTTObjectMapper: NSObject {

    static let classNameKey = "objectType"
    static let errorKey = "objectType"
    
    static func classByJsonObject(json:Any?) -> OTTBaseObject.Type? {
     
        
        let jsonObject = JSON(json)
        let className = jsonObject[classNameKey].string
        
        
        if let name = className{
            switch name {
            case "KalturaLoginResponse":
                return OTTLoginResponse.self
            case "KalturaSession":
                return OTTSession.self
            case "KalturaMediaAsset":
                return OTTAsset.self
            case "KalturaLoginSession":
                return OTTLoginSession.self
            case "KalturaPlaybackSource":
                return OTTPlaybackSource.self
            case "KalturaPlaybackContext":
                return OTTPlaybackContext.self
            default:
                return nil
            }
        } else {
            if jsonObject[errorKey].dictionary != nil {
                return OTTError.self
            }else{
                return nil
            }
            
        }
        
        
    }
    
    
    
    
    
    
  
}
