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

/// `PKBoundary` used as abstract for boundary types (% and time).
@objc public protocol PKBoundary {
    var time: TimeInterval { get }
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
    public let time: TimeInterval
    
    /// Creates a new `PKPercentageTimeBoundary` object from %.
    /// - Attention: boundary value should be between 1 and 100 otherwise will use default values!
    @objc public init(boundary: Int, duration: TimeInterval) {
        switch boundary {
        case 1...100: self.time = duration * TimeInterval(boundary) / TimeInterval(100)
        case Int.min...0: self.time = 0
        case 101...Int.max: self.time = duration
        default: self.time = 0
        }
    }
}

/// `PKTimeBoundary` represents a time boundary in seconds.
@objc public class PKTimeBoundary: NSObject, PKBoundary {
    
    /// The time to set the boundary on.
    @objc public let time: TimeInterval
    
    /// Creates a new `PKTimeBoundary` object from seconds.
    /// - Attention: boundary value should be between 0 and duration otherwise will use default values!
    @objc public init(boundaryTime: TimeInterval, duration: TimeInterval) {
        if boundaryTime <= 0 {
            self.time = 0
        } else if boundaryTime >= duration {
            self.time = duration
        } else {
            self.time = boundaryTime
        }
    }
}
