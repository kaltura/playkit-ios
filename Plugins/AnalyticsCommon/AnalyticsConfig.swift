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

@objc public class AnalyticsConfig: NSObject {
    
    @objc public var params: [String: Any]
    
    @objc public init(params: [String: Any]) {
        self.params = params
    }
}
