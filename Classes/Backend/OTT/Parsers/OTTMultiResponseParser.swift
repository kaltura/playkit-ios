// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

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
