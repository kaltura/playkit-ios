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
import CoreMedia

@objc public class PKTimeRange: NSObject {
    @objc public let start: TimeInterval
    @objc public let end: TimeInterval
    @objc public let duration: TimeInterval
    
    @objc public override var description: String {
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
