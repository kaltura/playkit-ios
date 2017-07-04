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

class OTTPlaybackContext: OTTBaseObject {

    var sources: [OTTPlaybackSource] = []

    required init?(json: Any) {
        let jsonObject = JSON(json)
        jsonObject["sources"].array?.forEach { (source: JSON) in
            if let source = OTTPlaybackSource(json: source.object) {
                sources.append(source)
            }
        }
    }
}
