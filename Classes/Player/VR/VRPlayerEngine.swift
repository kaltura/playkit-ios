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
import AVFoundation

/************************************************************/
// MARK: - ViewState
/************************************************************/

@objc public enum ViewState: Int, CustomStringConvertible {
    /// Sent when player's view state panorama.
    case panorama
    /// Sent when player's view state vr.
    case stereo
    /// Sent when player's view state errored.
    case error
    /// Sent when player's view state unknown.
    case unknown = -1
    
    public var description: String {
        switch self {
        case .panorama: return "Panorama"
        case .stereo: return "Stereo"
        case .error: return "Error"
        case .unknown: return "Unknown"
        }
    }
}

/************************************************************/
// MARK: - VRPlayerEngine
/************************************************************/

/// `VRPlayerEngine` protocol defines the methods needed to implement in order to work with the vr player engine.
@objc public protocol VRPlayerEngine: PlayerEngine {
    /// VRPlayerEngine initializer
    ///
    init()
    
    /// Current View State
    var currentViewState: ViewState { get }

    /// Enable VR Mode - Stereo display for Google's Cardboard.
    ///
    /// - Parameter isEnabled: Toggle to enable vr mode.
    func setVRModeEnabled(_ isEnabled: Bool)
    
    /// Requests reset of rotation in the next rendering frame.
    func centerViewPoint()
    
    /// Creates the orientation indicator view.
    ///
    /// - Parameter frame: The frame of orientation indicator view.
    func createOrientationIndicatorView(frame: CGRect) -> UIView?
}
