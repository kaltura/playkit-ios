// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import Foundation
import SwiftyJSON

class OTTPlaybackSource: OTTBaseObject {

    var assetId: Int
    var id: Int
    var type: String // file format
    var url: URL?
    var duration: Float
    var externalId: String?
    var protocols: [String]
    var format: String
    var drm: [OTTDrmData]?

    required init?(json: Any) {
        let jsonObject = JSON(json)

        guard let assetId = jsonObject["assetId"].int,
        let id = jsonObject["id"].int,
        let type = jsonObject["type"].string,
        let urlString = jsonObject["url"].string,
        let protocolsString = jsonObject["protocols"].string,
        let format = jsonObject["format"].string
        else {
            return nil
        }

        self.assetId = assetId
        self.id = id
        self.type = type
        self.url = URL.init(string: urlString)
        self.protocols = protocolsString.components(separatedBy: ",")
        self.format = format
        self.duration = jsonObject["duration"].float ?? 0
        self.externalId = jsonObject["externalId"].string

        var drmArray = [OTTDrmData]()
        jsonObject["drm"].array?.forEach {(json) in
            if let drmObject = OTTDrmData(json: json.object) {
                drmArray.append(drmObject)
            }
        }

        if drmArray.count > 0 {
            self.drm = drmArray
        }

    }
}
