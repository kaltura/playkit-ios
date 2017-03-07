//
//  KalturaOTTAnalyticsPluginProtocol
//  Pods
//
//  Created by Gal Orlanczyk on 31/01/2017.
//
//

import Foundation

enum OTTAnalyticsEventType: String {
    case hit
    case play
    case stop
    case pause
    case first_play
    case swoosh
    case load
    case finish
    case bitrate_change
    case error
}

protocol OTTAnalyticsPluginProtocol: AnalyticsPluginProtocol {
    
    var intervalOn: Bool { get set }
    var timer: Timer? { get set }
    var interval: TimeInterval { get set }
    
    func sendAnalyticsEvent(ofType type: OTTAnalyticsEventType)
    func buildRequest(ofType type: OTTAnalyticsEventType) -> Request?
    func send(request: Request)
}
