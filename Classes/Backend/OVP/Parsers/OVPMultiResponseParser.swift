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
    
    static func parse(data: Any) -> [OVPBaseObject] {
        
        let jsonResponse = JSON(data)
        if let resultArrayJSON = jsonResponse.array {
            
            var resultArray: [OVPBaseObject] = [OVPBaseObject]()
            for jsonResult: JSON in resultArrayJSON{
                var object: OVPBaseObject? = nil
                if let objects = jsonResult["objects"].array{
                    var parsedObjects: [OVPBaseObject] = [OVPBaseObject]()
                    for object in objects{
                        if  let OVPObject: OVPBaseObject = OVPMultiResponseParser.parseSingleItem(json: object){
                            parsedObjects.append(OVPObject)
                        }
                    }
                  object = OVPList(objects: parsedObjects)
                } else {
                    object = OVPMultiResponseParser.parseSingleItem(json: jsonResult)
                }
                
                if let obj = object{
                    resultArray.append(obj)
                }
            }
            return resultArray
        } else {
            return [OVPBaseObject]()
        }
    }
    
    static func  parseSingleItem(json:JSON) -> OVPBaseObject? {
        
        let objectType: OVPBaseObject.Type? = OVPObjectMapper.classByJsonObject(json: json.dictionaryObject)
        if let type = objectType{
            let object: OVPBaseObject? = type.init(json: json.object)
            return object
        } else {
            return nil
        }
    }
}
