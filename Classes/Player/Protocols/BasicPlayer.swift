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
    @objc var rate: Float { get }
    
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
    @objc func prepare(_ config: MediaConfig) throws
    
    /************************************************************/
    // MARK: - Time Observation
    /************************************************************/
    
    /// Adds a periodic time observer with specific interval
    ///
    /// - Parameters:
    ///   - interval: time interval for the periodic invocation.
    ///   - dispatchQueue: dispatch queue to observe changes on (nil value will use main).
    ///   - block: block to handle the observation.
    /// - Returns: A uuid token to represent the observation, used to later remove a single observation.
    @objc func addPeriodicObserver(interval: TimeInterval, observeOn dispatchQueue: DispatchQueue?, using block: @escaping (TimeInterval) -> Void) -> UUID
    
    /// Adds a boundary time observer for the selected boundaries in time (25%, 50%, 30s etc.)
    ///
    /// - Parameters:
    ///   - boundaries: boundary objects.
    ///   - dispatchQueue: dispatch queue to observe changes on (nil value will use main).
    ///   - block: block to handle the observation with the observed boundary, block returns (time, boundary percentage).
    /// - Returns: A uuid token to represent the observation, used to later remove a single observation.
    /// - Attention: if a boundary is crossed while seeking the observation **won't be triggered**.
    @objc func addBoundaryObserver(boundaries: [PKBoundary], observeOn dispatchQueue: DispatchQueue?, using block: @escaping (TimeInterval, Double) -> Void) -> UUID
    
    /// removes a single periodic observer using the uuid provided when added the observation.
    @objc func removePeriodicObserver(_ token: UUID)
    
    /// removes a single boundary observer using the uuid provided when added the observation.
    @objc func removeBoundaryObserver(_ token: UUID)
    
    /// removes a single periodic observer using the uuid provided when added the observation.
    @objc func removePeriodicObservers()
    
    /// removes a single boundary observer using the uuid provided when added the observation.
    @objc func removeBoundaryObservers()
}
