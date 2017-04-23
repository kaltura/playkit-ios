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

    enum OTTMultiResponseParserError: Error {
        case typeNotFound
        case emptyResponse
        case notMultiResponse
    }

    static func parse(data:Any) throws -> [OTTBaseObject] {

        let jsonResponse = JSON(data)
        if let resultArrayJSON = jsonResponse["result"].array {

            var resultArray: [OTTBaseObject] = [OTTBaseObject]()
            for jsonObject: JSON in resultArrayJSON {
                var object: OTTBaseObject? = nil
                let objectType: OTTBaseObject.Type? = OTTObjectMapper.classByJsonObject(json: jsonObject.dictionaryObject)
                if let type = objectType {
                     object = type.init(json: jsonObject.object)
                } else {
                    throw OTTMultiResponseParserError.typeNotFound
                }

                if let obj = object {
                    resultArray.append(obj)
                }
            }

            return resultArray
        } else {
            return [OTTBaseObject]()
        }
    }
}
