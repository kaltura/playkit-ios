//
//  OTTMultiResponseParser.swift
//  Pods
//
//  Created by Admin on 23/11/2016.
//
//

import UIKit
import SwiftyJSON

class OVPMultiResponseParser: NSObject {
    
    
    enum error: Error {
        case typeNotFound
        case emptyResponse
        case notMultiResponse
    }
    
    static func parse(data:Any) -> [Result<OVPBaseObject>] {
        
        let jsonResponse = JSON(data)
        if let resultArrayJSON = jsonResponse.array{
            
            var resultArray: [Result<OVPBaseObject>] = [Result<OVPBaseObject>]()
            for jsonResult: JSON in resultArrayJSON{
                // the result is list
                var resultObject: Result<OVPBaseObject>? = nil
                if let objects = jsonResult["objects"].array{
                    var parsedObjects: [OVPBaseObject] = [OVPBaseObject]()
                    for object in objects{
                        if  let OVPObject: OVPBaseObject = OVPMultiResponseParser.parseSingleItem(json: object){
                            parsedObjects.append(OVPObject)
                        }
                    }
                    
                  let list = OVPList(objects: parsedObjects)
                  resultObject = Result(data: list, error: nil)
                    
                }else{
                    
                    let object = OVPMultiResponseParser.parseSingleItem(json: jsonResult)
                    resultObject = Result(data: object, error: nil)
                // TODO:
                //the result is single object
                }
                
                if let result = resultObject{
                        resultArray.append(result)
                }
            }
            
            return resultArray
        }else{
            return [Result(data: nil, error: error.notMultiResponse)]
        }
    }
    
    static func  parseSingleItem(json:JSON) -> OVPBaseObject? {
        
        let objectType: OVPBaseObject.Type? = OVPObjectMapper.classByJsonObject(json: json.dictionaryObject)
        if let type = objectType{
            let object: OVPBaseObject? = type.init(json: json.object)
            return object
        }else{
            return nil
        }
    }
}
