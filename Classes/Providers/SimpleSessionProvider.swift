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
import KalturaNetKit

/**
 A SessionProvider that just reflects its input parameters -- baseUrl, partnerId, ks. 
 This class does not attempt to manage (create, renew, validate, clear) a session. 
 The application is expected to provide a valid KS, which it can update as required via the `ks` property. For some 
 use cases, the KS can be null (anonymous media playback, if allowed by access-control).  
 */
@objc public class SimpleSessionProvider: NSObject, SessionProvider {
    public let serverURL: String
    public let partnerId: Int64
    public var ks: String?
    
    /**
        Build a SessionProvider with the specified parameters.
        - Parameters:
            - serverURL: Kaltura Server URL, such as `"https://cdnapisec.kaltura.com"`.
            - partnerId: Kaltura partner id.
            - ks: Kaltura Session token.
     */
    @objc public init(serverURL: String, partnerId: Int64, ks: String?) {
        self.serverURL = serverURL
        self.partnerId = partnerId
        self.ks = ks
    }
    
    @objc public func loadKS(completion: @escaping (String?, Error?) -> Void) {
        completion(ks, nil)
    }
}

// Avoid breaking old code -- will be removed later. 
// Using a subclass instead of a typealias because typealiases are not exported to objective-c.
@available(*, deprecated, renamed: "SimpleSessionProvider")
@objc public class SimpleOVPSessionProvider: SimpleSessionProvider {}
