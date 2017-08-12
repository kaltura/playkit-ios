//
//  PKTimeRange.swift
//  Pods
//
//  Created by Gal Orlanczyk on 15/06/2017.
//
//

import Foundation
import CoreMedia

@objc public class PKTimeRange: NSObject {
    @objc public let start: TimeInterval
    @objc public let end: TimeInterval
    @objc public let duration: TimeInterval
    
    public override var description: String {
        return "[\(String(describing: type(of: self)))] - start: \(self.start), end: \(self.end), duration: \(self.duration)"
    }
    
    init(start: TimeInterval, duration: TimeInterval) {
        self.start = start
        self.duration = duration
        self.end = start + duration
    }
    
    convenience init(timeRange: CMTimeRange) {
        let start = CMTimeGetSeconds(timeRange.start)
        let duration = CMTimeGetSeconds(timeRange.duration)
        self.init(start: start, duration: duration)
    }
}
