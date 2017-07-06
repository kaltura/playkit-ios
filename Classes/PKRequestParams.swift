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

/// `PKRequestParamsDecorator` used for getting updated request info
@objc public protocol PKRequestParamsAdapter {
    func updateRequestAdapter(withPlayer player: Player)
    func adapt(requestParams: PKRequestParams) -> PKRequestParams
}

@objc public class PKRequestParams: NSObject {
    
    public let url: URL
    public let headers: [String: String]?
    
    init(url: URL, headers: [String: String]?) {
        self.url = url
        self.headers = headers
    }
}

