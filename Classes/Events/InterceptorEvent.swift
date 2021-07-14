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
//  InterceptorEvent.swift
//  PlayKit
//
//  Created by Sergey Chausov on 07.07.2021.
//

import Foundation

/// InterceptorEvent is a class that is used to reflect specific PKMediaEntryInterceptor events.
@objc public class InterceptorEvent: PKEvent {
    
    @objc public static let allEventTypes: [InterceptorEvent.Type] = [
        cdnSwitched
    ]
    
    // MARK: - Interceptor Events Static References.
    
    /// Sent by SmartSwitch interceptor plugin, when the playback URL changed with attached CDN code.
    /// Currently used by Youbora contentCdn options.
    @objc public static let cdnSwitched: InterceptorEvent.Type = CDNSwitched.self
    
    public class CDNSwitched: InterceptorEvent {
        public convenience init(cdnCode: String) {
            self.init([InterceptorEventDataKeys.cdnCode: cdnCode])
        }
        
        /// CDN code provided by plugins (SmartSwitch)
        @objc public var cdnCode: String? {
            return self.data?[InterceptorEventDataKeys.cdnCode] as? String
        }
    }
}

@objc public class InterceptorEventDataKeys: NSObject {
    
    public static let cdnCode = "CDNCode"
}
