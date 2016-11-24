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

    
    enum error: Error {
        case typeNotFound
        case emptyResponse
    }

    func parse(data:Any) -> Result<OTTBaseObject> {
     
        
            let jsonResponse = JSON(data)
            let resultObjectJSON = jsonResponse["result"].dictionaryObject
            let objectType: OTTBaseObject.Type? = ObjectMapper.classByJsonObject(json: resultObjectJSON)
            if let type = objectType{
                    let object: OTTBaseObject? = type.init(json: resultObjectJSON)
                return Result(data: object, error: nil)
            }else{
                return Result(data: nil, error: error.typeNotFound)
            }
    }
}



