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
    @objc public var sessionId: String?
    
    /// Installs a new kaltura request adapter on the provided player with custom application name.
    ///
    /// - Parameters:
    ///   - player: The player you want to use with the request adapter
    ///   - appName: the application name, if `nil` will use the bundle identifier.
    @objc public static func install(in player: Player, withAppName appName: String?) {
        let requestAdapter = KalturaUDRMLicenseRequestAdapter()
        requestAdapter.sessionId = player.sessionId
        requestAdapter.applicationName = appName
        player.settings.licenseRequestAdapter = requestAdapter
    }
    
    /// Updates the request adapter with info from the player
    @objc public func updateRequestAdapter(with player: Player) {
        self.sessionId = player.sessionId
    }
    
    /// Adapts the request params
    @objc public func adapt(requestParams: PKRequestParams) -> PKRequestParams {
        guard let sessionId = self.sessionId else { return requestParams }
        guard let urlComponents = URLComponents(url: requestParams.url, resolvingAgainstBaseURL: false) else { return requestParams }
        // Prepare clientTag
        let clientTag = PlayKitManager.clientTag
        // Prepare referrer
        var referrer = Bundle.main.bundleIdentifier ?? ""
        if let appName = self.applicationName {
            referrer = appName
        }
        referrer = self.base64(from: referrer)
        
        if #available(iOS 11.0, tvOS 11.0, *) {
            let url = requestParams.url
                .appendingPercentEncodedQueryComponent(key: "playSessionId", value: sessionId)
                .appendingPercentEncodedQueryComponent(key: "clientTag", value: clientTag)
                .appendingPercentEncodedQueryComponent(key: "referrer", value: referrer)
            
            return PKRequestParams(url: url, headers: requestParams.headers)
        } else {
            var licenceUrlString = requestParams.url.absoluteString
            
            var queryParameters: [String: String] = [
                "playSessionId": percentEncoded(sessionId),
                "clientTag": percentEncoded(clientTag),
                "referrer": percentEncoded(referrer)
            ]
            
            if urlComponents.queryItems == nil,
               let firstKey = queryParameters.keys.first {
                licenceUrlString = licenceUrlString.appending("?\(firstKey)=\(queryParameters.removeValue(forKey: firstKey) ?? "")")
            }
            
            for item in queryParameters {
                licenceUrlString = licenceUrlString.appending("&\(item.key)=\(item.value)")
            }
            
            // create the url
            guard let url = URL(string: licenceUrlString) else {
                PKLog.debug("failed to create url after appending query items")
                return requestParams
            }
            return PKRequestParams(url: url, headers: requestParams.headers)
        }
    }
    
}
