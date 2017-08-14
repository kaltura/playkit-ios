//
//  PKTimeBoundary.swift
//  Pods
//
//  Created by Gal Orlanczyk on 13/08/2017.
//
//

import Foundation
import CoreMedia

/// `PKTimeBoundary` represents a time boundary in % against the media duration.
@objc public class PKTimeBoundary: NSObject {
    
    /// The boundary in %. 
    /// for example when we want to add a boundary for the first quartile we will do boundary 25 (25%)
    let boundary: Int
    
    /// Creates a new `PKTimeBounddary` object.
    /// - Attention: boundary value should be between 1 and 100 otherwise will use default values!
    public init(boundary: Int) {
        switch boundary {
        case 1...100: self.boundary = boundary
        case Int.min...0: self.boundary = 1
        case 101...Int.max: self.boundary = 100
        default: self.boundary = 0
        }
    }
    
    func boundaryCMTimeValue(usingTime time: CMTime) -> NSValue {
        let boundaryTime = CMTimeMultiplyByFloat64(time, Float64(self.boundary)/Float64(100))
        return NSValue(time: boundaryTime)
    }
}
