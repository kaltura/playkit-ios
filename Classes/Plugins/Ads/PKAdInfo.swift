//
//  AdInfo.swift
//  Pods
//
//  Created by Gal Orlanczyk on 07/03/2017.
//
//

import Foundation

/// The position type of the ad according to the content timeline.
@objc public enum AdPositionType: Int {
    case preRoll
    case midRoll
    case postRoll
}

/// `PKAdInfo` represents ad information.
@objc public class PKAdInfo: NSObject {
    
    @objc public var adDescription: String
    @objc public var duration: TimeInterval
    @objc public var title: String
    @objc public var isSkippable: Bool
    @objc public var contentType: String
    @objc public var adId: String
    /// The source ad server information included in the ad response.
    @objc public var adSystem: String
    @objc public var height: Int
    @objc public var width: Int
    @objc public var podCount: Int
    @objc public var podPosition: Int
    /**
     The position of the pod in the content in seconds. Pre-roll returns 0,
     post-roll returns -1 and mid-rolls return the scheduled time of the pod.
     */
    @objc public var podTimeOffset: TimeInterval
    
    /// returns the position type of the ad (pre, mid, post)
    @objc public var positionType: AdPositionType {
        if podTimeOffset > 0 {
            return .midRoll
        } else if podTimeOffset < 0 {
            return .postRoll
        } else {
            return .preRoll
        }
    }
    
    init(adDescription: String,
         adDuration: TimeInterval,
         title: String,
         isSkippable: Bool,
         contentType: String,
         adId: String,
         adSystem: String,
         height: Int,
         width: Int,
         podCount: Int,
         podPosition: Int,
         podTimeOffset: TimeInterval) {
        
        self.adDescription = adDescription
        self.duration = adDuration
        self.title = title
        self.isSkippable = isSkippable
        self.contentType = contentType
        self.adId = adId
        self.adSystem = adSystem
        self.height = height
        self.width = width
        self.podCount = podCount
        self.podPosition = podPosition
        self.podTimeOffset = podTimeOffset
    }
}

extension PKEvent {
    /// Ad info, PKEvent Ad Data Accessor
    @objc public var adInfo: PKAdInfo? {
        return self.data?[AdEventDataKeys.adInfo] as? PKAdInfo
    }
}

