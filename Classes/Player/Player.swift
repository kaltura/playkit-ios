// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

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

@objc public protocol Player: BasicPlayer {
    
    @objc weak var delegate: PlayerDelegate? { get set }
    
    /// The player's associated media entry.
    @objc weak var mediaEntry: MediaEntry? { get }
    
    /// the player's settings
    @objc var settings: PlayerSettings { get }
    
    /// The player's session id. the `sessionId` is initialized when the player loads.
    @objc var sessionId: String { get }
    
    /// Prepare for playing an entry. play when it's ready. (preparing starts buffering the entry)
    @objc func prepare(_ config: MediaConfig)

    /// Add Observation to relevant event.
    @objc func addObserver(_ observer: AnyObject, event: PKEvent.Type, block: @escaping (PKEvent) -> Void)
    
    /// Add Observation to relevant events.
    @objc func addObserver(_ observer: AnyObject, events: [PKEvent.Type], block: @escaping (PKEvent) -> Void)
    
    /// Remove Observer for single event.
    @objc func removeObserver(_ observer: AnyObject, event: PKEvent.Type)
    
    /// Remove Observer for several events.
    @objc func removeObserver(_ observer: AnyObject, events: [PKEvent.Type])
    
    /// Update Plugin Config
    @objc func updatePluginConfig(pluginName: String, config: Any)
    
    #if os(iOS)
    /// Create PiP Controller
    @available(iOS 9.0, *)
    @objc func createPiPController(with delegate: AVPictureInPictureControllerDelegate) -> AVPictureInPictureController?
    #endif
}

public protocol PlayerDecoratorProvider {
    func getPlayerDecorator() -> PlayerDecoratorBase?
}


