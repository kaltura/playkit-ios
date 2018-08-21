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

@objc public class KalturaPlaybackRequestAdapter: NSObject, PKRequestParamsAdapter {
    
    private var applicationName: String?
    private var sessionId: String?
    
    /// Installs a new kaltura request adapter on the provided player with custom application name.
    ///
    /// - Parameters:
    ///   - player: The player you want to use with the request adapter
    ///   - appName: the application name, if `nil` will use the bundle identifier.
    @objc public static func install(in player: Player, withAppName appName: String) {
        let requestAdapter = KalturaPlaybackRequestAdapter()
        requestAdapter.sessionId = player.sessionId
        requestAdapter.applicationName = appName
        player.settings.contentRequestAdapter = requestAdapter
    }
    
    /// Updates the request adapter with info from the player
    @objc public func updateRequestAdapter(with player: Player) {
        self.sessionId = player.sessionId
    }
    
    /// Adapts the request params
    @objc public func adapt(requestParams: PKRequestParams) -> PKRequestParams {
        guard let sessionId = self.sessionId else { return requestParams }
        guard requestParams.url.path.contains("/playManifest/") else { return requestParams }
        guard var urlComponents = URLComponents(url: requestParams.url, resolvingAgainstBaseURL: false) else { return requestParams }
        // add query items to the request
        let queryItems = [
            URLQueryItem(name: "playSessionId", value: sessionId),
            URLQueryItem(name: "clientTag", value: PlayKitManager.clientTag),
            URLQueryItem(name: "referrer", value: self.applicationName == nil ? self.base64(from: Bundle.main.bundleIdentifier ?? "") : self.base64(from: self.applicationName!))
        ]
        if var urlQueryItems = urlComponents.queryItems {
            urlQueryItems += queryItems
            urlComponents.queryItems = urlQueryItems
        } else {
            urlComponents.queryItems = queryItems
        }
        // create the url
        guard let url = urlComponents.url else {
            PKLog.debug("failed to create url after appending query items")
            return requestParams
        }
        return PKRequestParams(url: url, headers: requestParams.headers)
    }
    
    private func base64(from: String) -> String {
        return from.data(using: .utf8)?.base64EncodedString() ?? ""
    }
}
