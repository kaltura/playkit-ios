// ===================================================================================================
// Copyright (C) 2019 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import Foundation
import AVFoundation

@objc public protocol BasicPlayer {
    /// The player item's asset.
    @objc var assetToPrepare: AVURLAsset? { get set }

    /// The player's duration.
    @objc var duration: TimeInterval { get }
    
    /// The player's currentState.
    @objc var currentState: PlayerState { get }
    
    /// Indicates if the player is playing.
    @objc var isPlaying: Bool { get }
    
    /// The player's view component.
    @objc weak var view: PlayerView? { get set }
    
    /// The current player's time.
    @objc var currentTime: TimeInterval { get set }
    
    /// The current program time (PROGRAM-DATE-TIME).
    @objc var currentProgramTime: Date? { get }
    
    /// Get the player's current audio track.
    @objc var currentAudioTrack: String? { get }
    
    /// Get the player's current text track.
    @objc var currentTextTrack: String? { get }
    
    /// Indicates the desired rate of playback, 0.0 means "paused", 1.0 indicates a desire to play at the natural rate of the current item.
    /// Note: Do not use the rate to indicate whether to play or pause! Use the isPlaying property.
    @objc var rate: Float { get set }
    
    /// The audio playback volume for the player, ranging from 0.0 through 1.0 on a linear scale.
    @objc var volume: Float { get set }
    
    /// Provides a collection of time ranges for which the player has the media data readily available. The ranges provided might be discontinuous.
    @objc var loadedTimeRanges: [PKTimeRange]? { get }
    
    /// Send a play action for the player.
    @objc func play()
    
    /// Send a pause action for the player.
    @objc func pause()
    
    /// Send a resume action for the player.
    @objc func resume()
    
    /// Send a stop action for the player.
    @objc func stop()
    
    /// Send a replay action for the player.
    @objc func replay()
    
    /// Send a seek action for the player.
    @objc func seek(to time: TimeInterval)
    
    /// Select a Track
    @objc func selectTrack(trackId: String)
    
    /// Release the player's resources.
    @objc func destroy()
    
    /// Prepare for playing an entry.
    /// If player network setting autoBuffer is set to true, prepare starts buffering the entry.
    /// Otherwise, if autoBuffer is set to false, need to call startBuffering manually.
    @objc func prepare(_ config: MediaConfig, mediaAsset: AVURLAsset?)
    
    /// Starts buffering the entry.
    @objc func startBuffering()
}
