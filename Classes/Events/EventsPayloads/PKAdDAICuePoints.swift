

import Foundation

@objc public class CuePoint: NSObject {
    @objc public private(set) var startTime: TimeInterval
    @objc public private(set) var endTime: TimeInterval
    @objc public private(set) var played: Bool
    
    @objc public init(startTime: TimeInterval, endTime: TimeInterval, played: Bool) {
        self.startTime = startTime
        self.endTime = endTime
        self.played = played
    }
    
    public override var description: String {
        return "StartTime:\(startTime) EndTime:\(endTime) Played:\(played)"
    }
}

@objc public class PKAdDAICuePoints: NSObject {
    
    @objc public private(set) var cuePoints: [CuePoint]
    
    @objc public init(_ cuePoints: [CuePoint]) {
        self.cuePoints = cuePoints
    }
    
    @objc public var hasPreRoll: Bool {
        return self.cuePoints.filter { $0.startTime == 0 }.count > 0 // pre-roll ads values = 0
    }
}
