//
//  IMAExtensions.swift
//  Pods
//
//  Created by Gal Orlanczyk on 17/04/2017.
//
//

import Foundation

import GoogleInteractiveMediaAds

extension IMAAdsManager {
    func getAdCuePoints() -> PKAdCuePoints {
        return PKAdCuePoints(cuePoints: self.adCuePoints as? [TimeInterval] ?? [])
    }
}

extension PKAdInfo {
    convenience init(ad: IMAAd) {
        self.init(
            adDescription: ad.adDescription,
            adDuration: ad.duration,
            title: ad.adTitle,
            isSkippable: ad.isSkippable,
            contentType: ad.contentType,
            adId: ad.adId,
            adSystem: ad.adSystem,
            height: Int(ad.height),
            width: Int(ad.width),
            podCount: Int(ad.adPodInfo.totalAds),
            podPosition: Int(ad.adPodInfo.adPosition),
            podTimeOffset: ad.adPodInfo.timeOffset
        )
    }
}
