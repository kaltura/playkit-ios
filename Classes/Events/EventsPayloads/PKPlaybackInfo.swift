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
    public let bitrate: Double
    /// The selected track indicated bitrate.
    public let indicatedBitrate: Double
    /// The throughput of the playback (download speed)
    public let observedBitrate: Double
    /// The playback framerate (this value is zero if it is not reported)
    @objc public let framesPerSecond: Float 
    
    init(bitrate: Double, 
         indicatedBitrate: Double, 
         observedBitrate: Double,
         framesPerSecond: Float) {
        self.bitrate = bitrate
        self.indicatedBitrate = indicatedBitrate
        self.observedBitrate = observedBitrate
        self.framesPerSecond = framesPerSecond
    }
    
    convenience init(logEvent: AVPlayerItemAccessLogEvent, 
                     playerItem: AVPlayerItem) {
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

        var framesPerSecond: Float = 0

        for track in playerItem.tracks {
            if track.assetTrack.mediaType == AVMediaType.video {
               framesPerSecond = track.currentVideoFrameRate 
            }
        }

        self.init(bitrate: bitrate, 
                  indicatedBitrate: indicatedBitrate, 
                  observedBitrate: observedBitrate,
                  framesPerSecond: framesPerSecond)
    }
}
