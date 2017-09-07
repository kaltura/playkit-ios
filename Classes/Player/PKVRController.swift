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
    
    required public init(player: PlayerEngine?) {
        self.currentPlayer = player as? VRPlayerEngine
    }
    
    /// Enable VR Mode - For stereo display for Google's Cardboard
    @objc public func setVRModeEnabled(_ isEnabled: Bool) {
        self.currentPlayer?.setVRModeEnabled(isEnabled)
    }
}
