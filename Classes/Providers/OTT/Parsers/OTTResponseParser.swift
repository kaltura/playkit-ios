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
    
    enum OTTResponseParserError: Error {
        case typeNotFound
        case invalidJsonObject
    }
    
    static func parse(data:Any) throws -> OTTBaseObject {
        
        let jsonResponse = JSON(data)
        let resultObjectJSON = jsonResponse["result"].dictionaryObject
        let objectType: OTTBaseObject.Type? = OTTObjectMapper.classByJsonObject(json: resultObjectJSON)
        if let type = objectType{
            if let object = type.init(json: resultObjectJSON) {
                return object
            }else{
              throw OTTResponseParserError.invalidJsonObject
            }
        }else{
            throw OTTResponseParserError.typeNotFound
        }
    }
}



