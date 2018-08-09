// ===================================================================================================
// Copyright (C) 2018 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import Foundation


@objc public class KalturaUDRMLicenseRequestAdapter: NSObject, PKRequestParamsAdapter {
    
    private var applicationName: String?
    
    /// Installs a new kaltura request adapter on the provided player with custom application name.
    ///
    /// - Parameters:
    ///   - player: The player you want to use with the request adapter
    ///   - appName: the application name, if `nil` will use the bundle identifier.
    @objc public static func install(in player: Player, withAppName appName: String) {
        let requestAdapter = KalturaUDRMLicenseRequestAdapter()
        requestAdapter.applicationName = appName
        player.settings.licenseRequestAdapter = requestAdapter
    }
    
    /// Updates the request adapter with info from the player
    @objc public func updateRequestAdapter(with player: Player) {
    }
    
    /// Adapts the request params
    @objc public func adapt(requestParams: PKRequestParams) -> PKRequestParams {
        var headers = requestParams.headers ?? [:]
        headers["Referrer"] = applicationName
        return PKRequestParams(url: requestParams.url, headers: headers)
    }
}
