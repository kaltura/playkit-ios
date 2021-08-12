// ===================================================================================================
// Copyright (C) 2021 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import Foundation
import KalturaNetKit

@objc public class NetworkUtils: NSObject {
    
    let defaultKavaBaseUrl: String = "https://analytics.kaltura.com/api_v3/index.php"
    let defaultKavaPartnerId: Int = 2504201
    let defaultKavaEntryId: String = "1_3bwzbc9o"
    
    static public let kavaEventImpression = "1"
    static public let kavaEventPlayRequest = "2"
    
    public func sendKavaAnalytics(forPartnerId partnerId: Int?, entryId: String?, eventType: String, sessionId: String) {
        guard let request: KalturaRequestBuilder = KalturaRequestBuilder(url: defaultKavaBaseUrl, service: nil, action: nil) else { return }
        
        var defPartnerId: Int = defaultKavaPartnerId
        var defEntryId: String = defaultKavaEntryId
        
        if let partnerId = partnerId, partnerId > 0,
           let entryId = entryId, !entryId.isEmpty {
            defPartnerId = partnerId
            defEntryId = entryId
        }
        
        request.set(method: .get)
        request.add(headerKey: "User-Agent", headerValue: PlayKitManager.userAgent)
        
        request.setParam(key: "service", value: "analytics")
        request.setParam(key: "action", value: "trackEvent")
        request.setParam(key: "eventType", value: eventType)
        request.setParam(key: "eventIndex", value: "1")
        request.setParam(key: "partnerId", value: String(defPartnerId))
        request.setParam(key: "entryId", value: defEntryId)
        request.setParam(key: "sessionId", value: sessionId)
        request.setParam(key: "referrer", value: self.base64(from: Bundle.main.bundleIdentifier ?? ""))
        request.setParam(key: "deliveryType", value: "url")
        request.setParam(key: "playbackType", value: "vod")
        request.setParam(key: "clientVer", value: "\(PlayKitManager.clientTag)")
        request.setParam(key: "position", value: "0")
        if let bundleId = Bundle.main.bundleIdentifier {
            request.setParam(key: "application", value: "\(bundleId)")
        }
        
        request.set { (response: Response) in
            PKLog.debug("Response:\nStatus Code: \(response.statusCode)\nError: \(response.error?.localizedDescription ?? "")\nData: \(response.data ?? "")")
        }
        PKLog.debug("Sending Kava Event, Impression (1)")
        KNKRequestExecutor.shared.send(request: request.build())
    }
    
    func base64(from: String) -> String {
        return from.data(using: .utf8)?.base64EncodedString() ?? ""
    }
    
}
