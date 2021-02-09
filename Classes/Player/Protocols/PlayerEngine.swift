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

@objc public protocol PlayerEngine: BasicPlayer {
    /// Fired when an event is triggred.
    var onEventBlock: ((PKEvent) -> Void)? { get set }
    
    /// The player's start position.
    var startPosition: TimeInterval { get set }
    
    /// The player's current position.
    var currentPosition: TimeInterval { get set }
    
    /// The current media config that was set.
    var mediaConfig: MediaConfig? { get set }
    
    /// The media playback type.
    var playbackType: String? { get }
    
    /// Load the media to the player.
    func loadMedia(from mediaSource: PKMediaSource?, mediaAsset: AVURLAsset?, handler: AssetHandler)
    
    /// Plays the live media from the live edge.
    func playFromLiveEdge()
    
    /// Update the text tracks styling.
    func updateTextTrackStyling(_ textTrackStyling: PKTextTrackStyling)
}
