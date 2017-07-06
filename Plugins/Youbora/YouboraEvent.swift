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

@objc public class YouboraEvent: PKEvent {
    
    class Report: YouboraEvent {
        convenience init(message: String) {
            self.init([YouboraEvent.messageKey: message])
        }
    }
    
    /// this event notifies when a youbora event is being sent
    @objc public static let report: YouboraEvent.Type = Report.self
    
    @objc public static let messageKey = "message"
}

extension PKEvent {
    /// Report Value, PKEvent Data Accessor
    @objc public var youboraMessage: String? {
        return self.data?[YouboraEvent.messageKey] as? String
    }
}
