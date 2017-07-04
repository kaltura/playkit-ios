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
import KalturaNetKit

class OVPSessionService {
        
    internal static func startWidgetSession(baseURL: String,
                                            partnerId: Int64 )  -> KalturaRequestBuilder? {
        
        if let request: KalturaRequestBuilder = KalturaRequestBuilder(url: baseURL,
                                                                      service: "session",
                                                                      action: "startWidgetSession") {
            
            request.setBody(key: "widgetId", value: JSON("_" + String(partnerId)))
            return request
        }else{
            return nil
        }
        
    }
}
