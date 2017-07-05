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

class OVPMetadata: OVPBaseObject {
    var xml:String?
    
    required init?(json: Any) {
        
        let jsonObject = JSON(json)
        self.xml = jsonObject["xml"].string
        
    }
    
}
