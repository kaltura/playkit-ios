// ===================================================================================================
// Copyright (C) 2021 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================
//

import Foundation
import SwiftyJSON

fileprivate let idKey = "id"
fileprivate let nameKey = "name"
fileprivate let thumbnailUrlKey = "thumbnailUrl"
fileprivate let mediasKey = "medias"

@objc public class PKPlaylist: NSObject {
    
    @objc public var id: String?
    @objc public var name: String?
    @objc public var thumbnailUrl: String?
    @objc public var medias: [PKMediaEntry]?
    
    @objc override public var description: String {
        get {
            return "id : \(self.id ?? "empty")," +
            " name: \(self.name ?? "empty")," +
            " thumbnailUrl: \(self.thumbnailUrl ?? "empty")"
        }
    }
    
    internal init(id: String?) {
        self.id = id
        super.init()
    }
    
    @objc public init(id: String?, name: String?, thumbnailUrl: String?, medias: [PKMediaEntry]) {
        self.id = id
        self.name = name
        self.thumbnailUrl = thumbnailUrl
        self.medias = medias
        super.init()
    }
    
    @objc public init(json: Any) {
        let jsonObject = json as? JSON ?? JSON(json)
        self.id = jsonObject[idKey].string
        self.name = jsonObject[nameKey].string
        
        super.init()
    }
}
