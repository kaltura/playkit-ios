// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
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

@objc public protocol PlayerEngine: BasicPlayer {
    /// Fired when some event is triggred.
    var onEventBlock: ((PKEvent) -> Void)? { get set }
    
    /// The player's start time.
    var startPosition: TimeInterval { get set }
    
    /// The player's current time.
    var currentPosition: TimeInterval { get set }
    
    var mediaConfig: MediaConfig? { get set }
    
    /// Load media on player
    func loadMedia(from mediaSource: PKMediaSource?, handler: AssetHandler)
}
