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


@objc public class CustomHeadersRequestAdapter: NSObject, PKRequestParamsAdapter {
    
    var customHTTPHeaders: [String: String]?
    
    @objc public func addHeaders(_ headers:[String: String]) {
        
        if self.customHTTPHeaders == nil {
            customHTTPHeaders = [:]
        }
        
        for (key, value) in headers {
            self.customHTTPHeaders?[key] = value
        }
    }
    
    
    @objc public func addCustomHeader(key: String, value: String) {
        self.customHTTPHeaders?[key] = value
    }
    
    @objc public static func install(in player: Player, withAppName appName: String) {
        let requestAdapter = CustomHeadersRequestAdapter()
//        requestAdapter.sessionId = player.sessionId
//        requestAdapter.applicationName = appName
        player.settings.contentRequestAdapter = requestAdapter
    }
    
    
    public func updateRequestAdapter(with player: Player) {
        
    }
    
    public func adapt(requestParams: PKRequestParams) -> PKRequestParams {
        var parameters = requestParams
        
        var newHeaders: [String: String] = [:]
        
        if let headers = parameters.headers {
            newHeaders = headers
        }
        
        
        
        return parameters
    }
    
}
//    public static func getPluginHeaders() -> [String : String] {
//        let token: String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE1MTYyMzkwMjIsIndtdmVyIjoyLCJ3bWlkZm10IjoiYXNjaWkiLCJ3bWlkdHlwIjoxLCJ3bWlkbGVuIjo1MTIsIndtb3BpZCI6MzIsIndtaWQiOiIyOTIxNmRmY2M0ZTIifQ.MvauSiNAvboiswsCkwD9_LkpCGSKcrLWaIFUsn2B9uM"
//
//        var headers: [String: String] = [:]
//        headers["Authorization"] = "Bearer " + token
//
//        return headers
//    }
