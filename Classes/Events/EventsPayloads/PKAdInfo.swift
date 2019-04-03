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
@objc public enum AdPositionType: Int, CustomStringConvertible {
    case preRoll
    case midRoll
    case postRoll
    
    public var description: String {
        switch self {
        case .preRoll: return "preRoll"
        case .midRoll: return "midRoll"
        case .postRoll: return "postRoll"
        }
    }
}

/// `PKAdInfo` represents ad information.
@objc public class PKAdInfo: NSObject {
    
    @objc public var duration: TimeInterval
    @objc public var title: String
    /// The position of the pod in the content in seconds. Pre-roll returns 0,
    /// post-roll returns -1 and mid-rolls return the scheduled time of the pod.
    @objc public var timeOffset: TimeInterval
    
    @objc public var adDescription: String
    @objc public var isSkippable: Bool
    @objc public var contentType: String
    @objc public var adId: String
    /// The source ad server information included in the ad response.
    @objc public var adSystem: String
    @objc public var height: Int
    @objc public var width: Int
    /// Total number of ads in the pod this ad belongs to. Will be 1 for standalone ads.
    @objc public var totalAds: Int
    /// The position of this ad within an ad pod. Will be 1 for standalone ads.
    @objc public var adPosition: Int
    @objc public var isBumper: Bool
    // The index of the pod, where pre-roll pod is 0, mid-roll pods are 1 .. N
    // and the post-roll is -1.
    @objc public var podIndex: Int
    // The bitrate of the selected creative.
    @objc public var mediaBitrate: Int
    // The CreativeId for the ad.
    @objc public var creativeId: String
    // The Advertiser Name for the ad.
    @objc public var advertiserName: String   
 
    /// returns the position type of the ad (pre, mid, post)
    @objc public var positionType: AdPositionType {
        if timeOffset > 0 {
            return .midRoll
        } else if timeOffset < 0 {
            return .postRoll
        } else {
            return .preRoll
        }
    }
    
    @objc public init(adDescription: String,
         adDuration: TimeInterval,
         title: String,
         isSkippable: Bool,
         contentType: String,
         adId: String,
         adSystem: String,
         height: Int,
         width: Int,
         totalAds: Int,
         adPosition: Int,
         timeOffset: TimeInterval,
         isBumper: Bool,
         podIndex: Int,
         mediaBitrate: Int,
         creativeId: String,
         advertiserName: String) {
        
        self.adDescription = adDescription
        self.duration = adDuration
        self.title = title
        self.isSkippable = isSkippable
        self.contentType = contentType
        self.adId = adId
        self.adSystem = adSystem
        self.height = height
        self.width = width
        self.totalAds = totalAds
        self.adPosition = adPosition
        self.timeOffset = timeOffset
        self.isBumper = isBumper
        self.podIndex = podIndex
        self.mediaBitrate = mediaBitrate
        self.creativeId = creativeId
        self.advertiserName = advertiserName
    }
    
    public override var description: String {
        return "adDescription: \(adDescription)\n" +
            "duration: \(duration)\n" +
            "title: \(title)\n" +
            "isSkippable: \(isSkippable)\n" +
            "contentType: \(contentType)\n" +
            "adId: \(adId)\n" +
            "adSystem: \(adSystem)\n" +
            "height: \(height)\n" +
            "width: \(width)\n" +
            "totalAds: \(totalAds)\n" +
            "adPosition: \(adPosition)\n" +
            "timeOffset: \(timeOffset)\n" +
            "isBumper: \(isBumper)\n" +
            "podIndex: \(podIndex)\n" +
            "mediaBitrate: \(mediaBitrate)\n" +
            "positionType: \(positionType)" + 
            "creativeId: \(creativeId)" +
            "advertiserName: \(advertiserName)"
    }
}
