//
//  Player.swift
//  PlayKit
//
//  Created by Noam Tamim on 28/08/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

@objc public protocol PlayerDelegate {
    func playerShouldPlayAd(_ player: Player) -> Bool
}

/// `PlayerSettings` used for optional `Player` settings.
@objc public protocol PlayerSettings {
    var contentRequestAdapter: PKRequestParamsAdapter? { get set }
}

@objc public protocol Player {
    
    @objc weak var delegate: PlayerDelegate? { get set }
    
    /// The player's associated media entry.
    @objc weak var mediaEntry: MediaEntry? { get }
    
    /// the player's settings
    @objc var settings: PlayerSettings { get }
    
    /// The player's view component.
    @objc var view: PlayerView { get }
    
    /// The current player position.
    @objc var currentTime: TimeInterval { get set }
    
    /// The player's duration.
    @objc var isPlaying: Bool { get }
    
    /// The player's duration.
    @objc var duration: TimeInterval { get }
    
    /// Get the player's current audio track.
    @objc var currentAudioTrack: String? { get }
    
    /// Get the player's current text track.
    @objc var currentTextTrack: String? { get }
    
    /// The player's session id. the `sessionId` is initialized when the player loads.
    @objc var sessionId: String { get }

    /// Indicates the desired rate of playback, 0.0 means "paused", 1.0 indicates a desire to play at the natural rate of the current item.
    @objc var rate: Float { get }
    
    /// Prepare for playing an entry. play when it's ready. (preparing starts buffering the entry)
    @objc func prepare(_ config: MediaConfig)
    
    /// send play action for the player.
    @objc func play()
    
    /// send pause action for the player.
    @objc func pause()
    
    /// send resume action for the player.
    @objc func resume()
    
    /// send stop action for the player.
    @objc func stop()
    
    /// send seek action for the player.
    @objc func seek(to time: CMTime)

    /// Release player resources.
    @objc func destroy()
    
    /// Add Observation to relevant event.
    @objc func addObserver(_ observer: AnyObject, events: [PKEvent.Type], block: @escaping (PKEvent) -> Void)
    
    /// Remove Observation.
    @objc func removeObserver(_ observer: AnyObject, events: [PKEvent.Type])
    
    /// Select Track
    @objc func selectTrack(trackId: String)
    
    /// Update Plugin Config
    @objc func updatePluginConfig(pluginName: String, config: Any)
    
    /// Create PiP Controller
    @available(iOS 9.0, *)
    @objc func createPiPController(with delegate: AVPictureInPictureControllerDelegate) -> AVPictureInPictureController?
}

public protocol PlayerDecoratorProvider {
    func getPlayerDecorator() -> PlayerDecoratorBase?
}

