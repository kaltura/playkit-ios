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
    /************************************************************/
    // MARK: - Properties
    /************************************************************/
    
    var currentPlayer: VRPlayerEngine?
    
    /// Represents current PKVRController view state
    ///
    /// ViewState Options
    ///   - panorama
    ///   - stereo
    ///   - error
    ///   - unknown
    @objc public var currentViewState: ViewState {
        
        guard let player = self.currentPlayer else {
            PKLog.warning("player doesn't exist")
            return ViewState.error
        }
        
        PKLog.debug("currentViewState: \(player.currentViewState)")
        return player.currentViewState
    }
    
    /************************************************************/
    // MARK: - Initialization
    /************************************************************/

    @objc required public init(player: PlayerEngine?) {
        self.currentPlayer = player as? VRPlayerEngine
    }
    
    /************************************************************/
    // MARK: - Functions
    /************************************************************/
    
    /// Enable VR Mode - For stereo display for Google's Cardboard.
    ///
    /// - Parameter isVREnabled: Toggle to enable vr mode.
    @objc public func setVRModeEnabled(_ isVREnabled: Bool) {
        PKLog.debug("isVREnabled: \(isVREnabled)")
        self.currentPlayer?.setVRModeEnabled(isVREnabled)
    }
    
    /// Requests reset of rotation in the next rendering frame.
    @objc public func centerViewPoint() {
        self.currentPlayer?.centerViewPoint()
    }
    
    /// Creates eye view indicator.
    ///
    /// - Parameter frame: eye view frame
    /// - Returns: eye view indicator
    @objc public func createOrientationIndicatorView(frame: CGRect) -> UIView? {
        guard let player = self.currentPlayer else {
            PKLog.warning("player doesn't exist")
            return nil
        }
        
        PKLog.debug("frame: \(frame)")
        return (player.createOrientationIndicatorView(frame: frame))
    }
}
