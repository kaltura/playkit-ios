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
    func set(contentRequestAdapter: PKRequestParamsAdapter)
}

@objc public protocol Player: PlayerSettings {
    
    @objc weak var delegate: PlayerDelegate? { get set }
    
    /// The player's associated media entry.
    weak var mediaEntry: MediaEntry? { get }
    
    var settings: PlayerSettings { get }
    
    /// The player's layer component.
    var view: UIView! { get }
    
    /// The current player position.
    var currentTime: TimeInterval { get set }
    
    /// The player's duration.
    var isPlaying: Bool { get }
    
    /// The player's duration.
    var duration: TimeInterval { get }
    
    var currentAudioTrack: String? { get }
    
    var currentTextTrack: String? { get }
    
    /// The player's session id. the `sessionId` is initialized when the player loads.
    var sessionId: UUID { get }
    
    /// Prepare for playing an entry. play when it's ready. (preparing starts buffering the entry)
    func prepare(_ config: MediaConfig)
    
    /// Send play action for the player.
    func play()
    
    /// Send pause action for the player.
    func pause()
    
    /// Send resume action for the player.
    func resume()
    
    /// Send stop action for the player.
    func stop()
    
    /// Send seek action for the player.
    func seek(to time: CMTime)
    
    /// Release player resources.
    func destroy()
    
    func addObserver(_ observer: AnyObject, events: [PKEvent.Type], block: @escaping (PKEvent)->Void)
    
    func removeObserver(_ observer: AnyObject, events: [PKEvent.Type])
    
    func selectTrack(trackId: String)
    
    @available(iOS 9.0, *)
    func createPiPController(with delegate: AVPictureInPictureControllerDelegate) -> AVPictureInPictureController?
}

protocol PlayerDecoratorProvider: NSObjectProtocol {
    func getPlayerDecorator() -> PlayerDecoratorBase?
}

