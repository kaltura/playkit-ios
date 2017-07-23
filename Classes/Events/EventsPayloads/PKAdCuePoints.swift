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

@objc public class PKAdCuePoints: NSObject {
    
    @objc public private(set) var cuePoints: [TimeInterval]
    
    @objc public init(cuePoints: [TimeInterval]) {
        self.cuePoints = cuePoints.sorted() // makes sure array is sorted
    }
    
    @objc public var count: Int {
        return self.cuePoints.count
    }
    
    @objc public var hasPreRoll: Bool {
        return self.cuePoints.filter { $0 == 0 }.count > 0 // pre-roll ads values = 0
    }
    
    @objc public var hasMidRoll: Bool {
        return self.cuePoints.filter { $0 > 0 }.count > 0
    }
    
    @objc public var hasPostRoll: Bool {
        return self.cuePoints.filter { $0 < 0 }.count > 0 // post-roll ads values = -1
    }
}
