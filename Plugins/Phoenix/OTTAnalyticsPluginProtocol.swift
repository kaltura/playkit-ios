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
import KalturaNetKit

enum OTTAnalyticsEventType: String {
    case hit
    case play
    case stop
    case pause
    case first_play
    case swoosh
    case load
    case finish
    case bitrateChange
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
