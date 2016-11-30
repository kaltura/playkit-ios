//
//  OTTMultiResponseParser.swift
//  Pods
//
//  Created by Admin on 23/11/2016.
//
//

import UIKit
import SwiftyJSON

class OTTMultiResponseParser: NSObject {
    
    
    enum error: Error {
        case typeNotFound
        case emptyResponse
        case notMultiResponse
    }
    
    static func parse(data:Any) -> [Result<OTTBaseObject>] {
        
        let jsonResponse = JSON(data)
        if let resultArrayJSON = jsonResponse["result"].array{
            
            var resultArray: [Result<OTTBaseObject>] = [Result<OTTBaseObject>]()
            for jsonObject: JSON in resultArrayJSON{
                let objectType: OTTBaseObject.Type? = OTTObjectMapper.classByJsonObject(json: jsonObject.dictionaryObject)
                if let type = objectType{
                    let object: OTTBaseObject? = type.init(json: jsonObject.object)
                    resultArray.append(Result(data: object, error: nil))
                }else{
                    resultArray.append(Result(data: nil, error: error.typeNotFound))
                }
                
            }
            
            return resultArray
        }else{
            return [Result(data: nil, error: error.notMultiResponse)]
        }
    }
}
