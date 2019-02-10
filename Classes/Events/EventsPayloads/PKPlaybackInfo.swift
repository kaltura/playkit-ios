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
import AVFoundation

/// `PKPlaybackInfo` represents a playback info object.
@objc public class PKPlaybackInfo: NSObject {
    
    /// The actual bitrate of the playback.
    @objc public let bitrate: Double
    /// The selected track indicated bitrate.
    @objc public let indicatedBitrate: Double
    /// The throughput of the playback (download speed)
    @objc public let observedBitrate: Double
    
    init(bitrate: Double, indicatedBitrate: Double, observedBitrate: Double) {
        self.bitrate = bitrate
        self.indicatedBitrate = indicatedBitrate
        self.observedBitrate = observedBitrate
    }
    
    convenience init(logEvent: AVPlayerItemAccessLogEvent) {
        let bitrate: Double
        if logEvent.segmentsDownloadedDuration > 0 {
            // bitrate is equal to:
            // (amount of bytes transfered) * 8 (bits in byte) / (amount of time took to download the transfered bytes)
            bitrate = Double(logEvent.numberOfBytesTransferred * 8) / logEvent.segmentsDownloadedDuration
        } else {
            bitrate = logEvent.indicatedBitrate
        }
        let indicatedBitrate = logEvent.indicatedBitrate
        let observedBitrate = logEvent.observedBitrate
        self.init(bitrate: bitrate, indicatedBitrate: indicatedBitrate, observedBitrate: observedBitrate)
    }
}
