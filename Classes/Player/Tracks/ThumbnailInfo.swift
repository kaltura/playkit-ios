// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================


import AVFoundation

//AG!

@objc public class ThumbnailInfo: NSObject {
    public let image: UIImage
    public let requestedPosition: Float64
    public let actualPosition: Float64
    
    public init(image: UIImage, requestedPosition: Float64, actualPosition: Float64) {
        self.image = image
        self.requestedPosition = requestedPosition
        self.actualPosition = actualPosition
    }
}


@objc public class ThumbnailRequestParams: NSObject {
    var maximumSize: CGSize?
    var requestedTimeToleranceBefore: CMTime?
    var requestedTimeToleranceAfter: CMTime?
    var dynamicRangePolicy: AVAssetImageGenerator.DynamicRangePolicy?
    var appliesPreferredTrackTransform: Bool = true
    var apertureMode: AVAssetImageGenerator.ApertureMode?
    
    public init(maximumSize: CGSize? = nil, requestedTimeToleranceBefore: CMTime? = nil, requestedTimeToleranceAfter: CMTime? = nil, dynamicRangePolicy: AVAssetImageGenerator.DynamicRangePolicy? = nil, appliesPreferredTrackTransform: Bool = true, apertureMode: AVAssetImageGenerator.ApertureMode? = nil) {
        self.maximumSize = maximumSize
        self.requestedTimeToleranceBefore = requestedTimeToleranceBefore
        self.requestedTimeToleranceAfter = requestedTimeToleranceAfter
        self.dynamicRangePolicy = dynamicRangePolicy
        self.appliesPreferredTrackTransform = appliesPreferredTrackTransform
        self.apertureMode = apertureMode
    }
}
