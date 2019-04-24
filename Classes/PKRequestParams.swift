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
    /// Called when need to update the request adapter with information from the player.
    /// Use this to update the adapter with any information available from the player.
    /// 
    /// For example, when media session id changes.
    @objc func updateRequestAdapter(with player: Player)
    @objc func adapt(requestParams: PKRequestParams) -> PKRequestParams
}

@objc public class PKRequestParams: NSObject {
    
    @objc public let url: URL
    @objc public let headers: [String: String]?
    
    @objc public init(url: URL, headers: [String: String]?) {
        self.url = url
        self.headers = headers
    }
}
