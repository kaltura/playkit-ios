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

class OTTResponseParser: NSObject {

    enum OTTResponseParserError: Error {
        case typeNotFound
        case invalidJsonObject
    }

    static func parse(data:Any) throws -> OTTBaseObject {

        let jsonResponse = JSON(data)
        let resultObjectJSON = jsonResponse["result"].dictionaryObject
        let objectType: OTTBaseObject.Type? = OTTObjectMapper.classByJsonObject(json: resultObjectJSON)
        if let type = objectType, let resultJSON = resultObjectJSON {
            if let object = type.init(json: resultJSON) {
                return object
            } else {
              throw OTTResponseParserError.invalidJsonObject
            }
        } else {
            throw OTTResponseParserError.typeNotFound
        }
    }
}
