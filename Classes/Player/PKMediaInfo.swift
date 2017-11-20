// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================


/************************************************************/
// MARK: - PKMediaInfo
/************************************************************/

/// `PKMediaInfo` object contains general info about current media.

@objc public class PKMediaInfo: NSObject {
    
    /************************************************************/
    // MARK: - Properties
    /************************************************************/
    
    /// Current media format.
    @objc public var format: PKMediaSource.MediaFormat = PKMediaSource.MediaFormat.unknown
    /// Current media type
    @objc public var type: MediaType = MediaType.unknown
    
    /************************************************************/
    // MARK: - Functions
    /************************************************************/
    
    /// Indicates if current media is Live DVR or not.
    ///
    /// - Parameters:
    ///   - duration: media duration.
    ///   - currentTime: current media position.
    /// - Returns: returns true if it's dvr.
    static public func isDVR(duration: Double?, currentTime: Double?) -> Bool {
        let distanceFromLiveThreshold = 1500
        guard let mediaDuration = duration, let mediaCurrentTime = currentTime else {
            PKLog.warning("duration/ current time are not set")
            return false
        }
        
        let distanceFromLive = Double(mediaDuration) - Double(mediaCurrentTime)
        
        return distanceFromLive > Double(distanceFromLiveThreshold)
    }
}
