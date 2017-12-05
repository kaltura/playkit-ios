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

@objc public protocol BasicPlayer {
    /// The player's duration.
    @objc var duration: TimeInterval { get }
    
    /// The player's currentState.
    @objc var currentState: PlayerState { get }
    
    /// Indicates if player is playing.
    @objc var isPlaying: Bool { get }
    
    /// The player's view component.
    @objc weak var view: PlayerView? { get set }
    
    /// The current player position.
    @objc var currentTime: TimeInterval { get set }
    
    /// Get the player's current audio track.
    @objc var currentAudioTrack: String? { get }
    
    /// Get the player's current text track.
    @objc var currentTextTrack: String? { get }
    
    /// Indicates the desired rate of playback, 0.0 means "paused", 1.0 indicates a desire to play at the natural rate of the current item.
    @objc var rate: Float { get set }
    
    /// Provides a collection of time ranges for which the player has the media data readily available. The ranges provided might be discontinuous.
    @objc var loadedTimeRanges: [PKTimeRange]? { get }
    
    /// send play action for the player.
    @objc func play()
    
    /// send pause action for the player.
    @objc func pause()
    
    /// send resume action for the player.
    @objc func resume()
    
    /// send stop action for the player.
    @objc func stop()
    
    /// send seek action for the player.
    @objc func seek(to time: TimeInterval)
    
    /// Select Track
    @objc func selectTrack(trackId: String)
    
    /// Release player resources.
    @objc func destroy()
    
    /// Prepare for playing an entry. play when it's ready. (preparing starts buffering the entry)
    @objc func prepare(_ config: MediaConfig)
}
