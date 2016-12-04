//
//  OTTRequestParser.swift
//  Pods
//
//  Created by Admin on 23/11/2016.
//
//

import UIKit
import SwiftyJSON

class OTTResponseParser: ResponseParser {
    
    
    static func parse(data:Any) -> OTTBaseObject {
        
        let jsonResponse = JSON(data)
        let resultObjectJSON = jsonResponse["result"].dictionaryObject
        let objectType: OTTBaseObject.Type? = OTTObjectMapper.classByJsonObject(json: resultObjectJSON)
        if let type = objectType{
            if let object = type.init(json: resultObjectJSON) {
                return object
            }else{
              return OTTError()
            }
        }else{
            return OTTError()
        }
    }
}



