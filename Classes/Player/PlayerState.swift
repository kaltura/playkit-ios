// ===================================================================================================
// Copyright (C) 2018 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

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

/// An PlayerState is an enum of different player states
@objc public enum PlayerState: Int, CustomStringConvertible {
    /// Sent when player's state idle.
    case idle
    /// Sent when player's state ready.
    case ready
    /// Sent when player's state buffering.
    case buffering
    /// Sent when player's state ended.
    /// Same event sent when observing PlayerEvent.ended.
    /// This state was attached to reflect current state and avoid unrelevant boolean.
    case ended
    /// Sent when player's state errored.
    case error
    /// Sent when player's state unknown.
    case unknown = -1
    
    public var description: String {
        switch self {
        case .idle: return "Idle"
        case .ready: return "Ready"
        case .buffering: return "Buffering"
        case .ended: return "Ended"
        case .error: return "Error"
        case .unknown: return "Unknown"
        }
    }
}
