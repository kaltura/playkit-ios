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

/// A State is an enum of different player states
@objc public enum ViewState: Int {
    /// Sent when player's view state panorama.
    case panorama
    /// Sent when player's view state vr.
    case stereo
    /// Sent when player's view state errored.
    case error
    /// Sent when player's view state unknown.
    case unknown = -1
}

public protocol VRPlayerEngine: PlayerEngine {
    init(delegate: PlayerDelegate?)
    var currentViewState: ViewState { get }
    var isEnabled: Bool { get set }
    func setVRModeEnabled(_ isEnabled: Bool)
    func centerViewPoint()
}
