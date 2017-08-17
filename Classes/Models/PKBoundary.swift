//
//  PKTimeBoundary.swift
//  Pods
//
//  Created by Gal Orlanczyk on 13/08/2017.
//
//

import Foundation
import CoreMedia

@objc public protocol PKBoundary {
    var time: CMTime { get }
}

/// `PKBoundaryFactory` factory class used to create boundary objects easily.
@objc public class PKBoundaryFactory: NSObject {
    
    let duration: TimeInterval
    
    @objc public init (duration: TimeInterval) {
        self.duration = duration
    }
    
    @objc public func percentageTimeBoundary(boundary: Int) -> PKPercentageTimeBoundary {
        return PKPercentageTimeBoundary(boundary: boundary, duration: self.duration)
    }
    
    @objc public func timeBoundary(boundaryTime: TimeInterval) -> PKTimeBoundary {
        return PKTimeBoundary(boundaryTime: boundaryTime, duration: self.duration)
    }
}

/// `PKPercentageTimeBoundary` represents a time boundary in % against the media duration.
@objc public class PKPercentageTimeBoundary: NSObject, PKBoundary {
    
    /// The time to set the boundary on.
    public let time: CMTime
    
    /// Creates a new `PKPercentageTimeBoundary` object from %.
    /// - Attention: boundary value should be between 1 and 100 otherwise will use default values!
    @objc public init(boundary: Int, duration: TimeInterval) {
        switch boundary {
        case 1...100: self.time = CMTimeMultiplyByFloat64(CMTimeMakeWithSeconds(duration, 1), Float64(boundary)/Float64(100))
        case Int.min...0: self.time = CMTimeMultiplyByFloat64(CMTimeMakeWithSeconds(duration, 1), Float64(1)/Float64(100))
        case 101...Int.max: self.time = CMTimeMultiplyByFloat64(CMTimeMakeWithSeconds(duration, 1), Float64(100)/Float64(100))
        default: self.time = CMTimeMultiplyByFloat64(CMTimeMakeWithSeconds(duration, 1), Float64(0)/Float64(100))
        }
    }
}

/// `PKTimeBoundary` represents a time boundary in seconds.
@objc public class PKTimeBoundary: NSObject, PKBoundary {
    
    /// The time to set the boundary on.
    public let time: CMTime
    
    /// Creates a new `PKTimeBoundary` object from seconds.
    /// - Attention: boundary value should be between 0 and duration otherwise will use default values!
    @objc public init(boundaryTime: TimeInterval, duration: TimeInterval) {
        if boundaryTime <= 0 {
            self.time = CMTimeMakeWithSeconds(0, 1)
        } else if boundaryTime >= duration {
            self.time = CMTimeMakeWithSeconds(duration, 1)
        } else {
            self.time = CMTimeMakeWithSeconds(boundaryTime, 1)
        }
    }
}
