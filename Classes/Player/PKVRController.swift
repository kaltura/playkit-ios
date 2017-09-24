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

@objc public class PKVRController: NSObject, PKController {
    var currentPlayer: VRPlayerEngine?
    
    /// 
    @objc public var isEnabled: Bool {
        return (self.currentPlayer?.isEnabled)!
    }
    
    required public init(player: PlayerEngine?) {
        self.currentPlayer = player as? VRPlayerEngine
    }
    
    /// Enable VR Mode - For stereo display for Google's Cardboard.
    @objc public func setVRModeEnabled(_ isVREnabled: Bool) {      
        self.currentPlayer?.setVRModeEnabled(isVREnabled)
    }
    
    /// Requests reset of rotation in the next rendering frame.
    @objc public func centerViewPoint() {
        self.currentPlayer?.centerViewPoint()
    }
}
