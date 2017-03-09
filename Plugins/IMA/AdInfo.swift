//
//  AdInfo.swift
//  Pods
//
//  Created by Gal Orlanczyk on 07/03/2017.
//
//

import Foundation
import GoogleInteractiveMediaAds

@objc public class AdInfo: NSObject {
    @objc public var adDescription: String
    @objc public var duration: TimeInterval
    @objc public var title: String
    @objc public var isSkippable: Bool
    @objc public var contentType: String
    @objc public var adId: String
    @objc public var adSystem: String
    @objc public var height: Int
    @objc public var width: Int
    @objc public var podCount: Int
    @objc public var podPosition: Int
    @objc public var podTimeOffset: TimeInterval
    
    init(ad: IMAAd) {
        self.adDescription = ad.adDescription
        self.duration = ad.duration
        self.title = ad.adTitle
        self.isSkippable = ad.isSkippable
        self.contentType = ad.contentType
        self.adId = ad.adId
        self.adSystem = ad.adSystem
        self.height = Int(ad.height)
        self.width = Int(ad.width)
        self.podCount = Int(ad.adPodInfo.totalAds)
        self.podPosition = Int(ad.adPodInfo.adPosition)
        self.podTimeOffset = ad.adPodInfo.timeOffset
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

extension AdEvent {
    
    @objc public static let adInformation: AdEvent.Type = AdInfomation.self
    
    class AdInfomation: AdEvent {
        convenience init(adInfo: AdInfo) {
            self.init([AdEventDataKeys.adInfo: adInfo])
        }
    }
}

extension PKEvent {
    
    /// Ad info, PKEvent Ad Data Accessor
    @objc public var adInfo: AdInfo? {
        return self.data?[AdEventDataKeys.adInfo] as? AdInfo
    }
}

