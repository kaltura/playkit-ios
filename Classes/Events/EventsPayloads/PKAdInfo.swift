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

/// The position type of the ad according to the content timeline.
@objc public enum AdPositionType: Int {
    case pre
    case mid
    case post
    
    var asString: String {
        switch self {
        case .pre: return "pre"
        case .mid: return "mid"
        case .post: return "post"
        }
    }
}

/// `PKAdInfo` represents ad information.
@objc public class PKAdInfo: NSObject {
    
    @objc public var title: String
    /// The position of the pod in the content in seconds. Pre-roll returns 0,
    /// post-roll returns -1 and mid-rolls return the scheduled time of the pod.
    @objc public var timeOffset: TimeInterval
    /// The ad duration.
    @objc public var duration: TimeInterval
    /// the ad description
    @objc public var adDescription: String?
    @objc public var skipOffset: NSNumber?
    /// The ad id from the vast respone
    @objc public var adId: String
    /// The source ad server information included in the ad response.
    @objc public var adSystem: String
    /// Total number of ads in the pod this ad belongs to. Will be 1 for standalone ads.
    @objc public var totalAds: Int
    /// The position of this ad within an ad pod. Will be 1 for standalone ads.
    @objc public var position: Int
    /// returns the position type of the ad (pre, mid, post)
    @objc public let positionType: AdPositionType
    
    public init(description: String?,
         duration: TimeInterval,
         title: String,
         skipOffset: NSNumber?,
         adId: String,
         adSystem: String,
         totalAds: Int,
         position: Int,
         timeOffset: TimeInterval) {
        
        self.adDescription = description
        self.duration = duration
        self.title = title
        self.skipOffset = skipOffset
        self.adId = adId
        self.adSystem = adSystem
        self.totalAds = totalAds
        self.position = position
        self.timeOffset = timeOffset
        
        if timeOffset > 0 {
            self.positionType = .mid
        } else if timeOffset < 0 {
            self.positionType = .post
        } else {
            self.positionType = .pre
        }
    }
    
    public override var description: String {
        return "id: \(self.adId), title: \(self.title), timeOffset: \(self.timeOffset), duration: \(self.duration), position: (\(self.position), \(self.positionType.asString)), totalAds: \(self.totalAds), adSystem: \(self.adSystem), skipOffset: \(String(describing: self.skipOffset))"
    }
}

@objc public enum PKAdEndedReasonType: Int {
    /// ad has completed
    case completed
    /// ad was skipped
    case skipped
    /// when ad failed and error url was given back.
    case adError
    
    var asString: String {
        switch self {
        case .completed: return "completed"
        case .skipped: return "skipped"
        case .adError: return "adError"
        }
    }
}

@objc public class PKAdEndedReason: NSObject {
    
    @objc public var reasonType: PKAdEndedReasonType
    @objc public let offset: NSNumber?
    
    @objc public init(reasonType: PKAdEndedReasonType, offset: NSNumber?) {
        self.reasonType = reasonType
        self.offset = offset
    }
    
    public override var description: String {
        return "reason: \(self.reasonType.asString), offset: \(String(describing: offset))"
    }
}

