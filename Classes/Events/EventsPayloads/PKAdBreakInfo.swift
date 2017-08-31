//
//  PKAdBreakInfo.swift
//  Pods
//
//  Created by Gal Orlanczyk on 29/08/2017.
//
//

import Foundation

@objc public class PKAdBreakInfo: NSObject {
    /// the id of the ad break from the VMAP response.
    @objc public let id: String
    /// The position of the ad break from total ad breaks.
    ///
    /// For example: first ad break out of 3 ad breaks in total will have position 1 out of 3.
    @objc public let position: Int
    /// The position type of the ad (pre, mid, post)
    @objc public let positionType: AdPositionType
    /// Total number of ad breaks
    @objc public let totalAdBreaks: Int
    /// The offset of the ad break in the content in seconds.
    /// Pre-roll returns 0, post-roll returns -1 and mid-rolls return the scheduled time of the ad break.
    @objc public let timeOffset: TimeInterval
    /// Total number of ads in the ad break.
    @objc public var totalAds: NSNumber?
    
    @objc public init(id: String, position: Int, totalAdBreaks: Int, timeOffset: TimeInterval, totalAds: NSNumber?) {
        
        self.id = id
        self.position = position
        self.totalAdBreaks = totalAdBreaks
        self.timeOffset = timeOffset
        if timeOffset > 0 {
            self.positionType = .mid
        } else if timeOffset < 0 {
            self.positionType = .post
        } else {
            self.positionType = .pre
        }
        self.totalAds = totalAds
    }
    
    public override var description: String {
        return "id: \(self.id), position: (\(self.position), \(self.positionType.asString)), totalAdBreaks: \(self.totalAdBreaks), timeOffset: \(self.timeOffset), totalAds: \(String(describing: self.totalAds))"
    }
}

@objc public enum PKAdBreakEndedReasonType: Int {
    /// ad break has completed (even if some of the ads were skipped).
    case completed
    /// ad break has been discarded by calling discardAdBreak().
    case discarded
    /// when vast was failed and we got error url.
    case vastError
    /// ad break ended because of an error.
    case error
    
    var asString: String {
        switch self {
        case .completed: return "completed"
        case .discarded: return "discarded"
        case .vastError: return "vastError"
        case .error: return "error"
        }
    }
}

@objc public class PKAdBreakEndedReason: NSObject {
    @objc public var reasonType: PKAdBreakEndedReasonType
    @objc public let error: NSError?
    
    @objc public init(reasonType: PKAdBreakEndedReasonType, error: NSError?) {
        self.reasonType = reasonType
        self.error = error
    }
    
    public override var description: String {
        return "reason: \(self.reasonType.asString), error: \(String(describing: error?.localizedDescription))"
    }
}
