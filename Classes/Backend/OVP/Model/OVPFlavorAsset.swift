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

@objc public enum CodecType: Int {
    case h265
    case h264
    case unknown
    
    init(codecId: String) {
        switch codecId {
        case "hev1", "hvc1": self = .h265
        case "avc1": self = .h264
        default: self = .unknown
        }
    }
}

class OVPFlavorAsset: OVPBaseObject {

    let id: String
    let tags: String?
    let fileExt: String?
    let paramsId: Int
    let videoCodecId: String
    let codecType: CodecType
    
    let idKey = "id"
    let tagsKey = "tags"
    let fileExtKey = "fileExt"
    let paramsIdKey = "flavorParamsId"
    let videoCodecIdKey = "videoCodecId" // FIXME: make sure key is correct!
    
    init(id: String, tags: String?, fileExt: String?, paramsId: Int, videoCodecId: String) {
        self.id = id
        self.tags = tags
        self.fileExt = fileExt
        self.paramsId = paramsId
        self.videoCodecId = videoCodecId
        self.codecType = CodecType(codecId: self.videoCodecId)
    }
    
    required init?(json: Any) {
        let jsonObject = JSON(json)
        if let id = jsonObject[idKey].string, let paramID = jsonObject[paramsIdKey].int, let videoCodecId = jsonObject[videoCodecIdKey].string {
            self.id = id
            self.paramsId = paramID
            self.videoCodecId = videoCodecId
        } else {
            return nil
        }
        
        self.tags = jsonObject[tagsKey].string
        self.fileExt = jsonObject[fileExtKey].string
        self.codecType = CodecType(codecId: self.videoCodecId)
    }
}
