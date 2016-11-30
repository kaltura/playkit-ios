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
                return OTTLogin.self
            case "KalturaSession":
                return OTTSession.self
                

            default:
                return nil
            }
        }else{
            if let jsonError = jsonObject[errorKey].dictionary {
                return OTTError.self
            }else{
                return nil
            }
            
        }
        
        
    }
    
    
    
    
    
    
  
}
