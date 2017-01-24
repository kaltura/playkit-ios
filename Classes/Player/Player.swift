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

@objc public protocol PlayerDelegate: class {
    func playerShouldPlayAd(_ player: Player) -> Bool
    func player(_ player: Player, failedWith error: String)
}

@objc public protocol Player: NSObjectProtocol {
    
    @objc var delegate: PlayerDelegate? { get set }
        
    /**
     Get the player's layer component.
     */
    var view: UIView! { get }
    
    /**
     Get/set the current player position.
     */
    var currentTime: TimeInterval { get set }
    
    /**
     Get the player's duration.
     */
    var isPlaying: Bool { get }
    
    /**
     Get the player's duration.
     */
    var duration: Double { get }
    
    var currentAudioTrack: String? { get }
    
    var currentTextTrack: String? { get }
    
    /**
     Prepare for playing an entry.
     play when it's ready.
     */
    func prepare(_ config: PlayerConfig)
    
    /**
     Convenience method for setting shouldPlayWhenReady to true.
     */
    func play()
    
    /**
     Convenience method for setting shouldPlayWhenReady to false.
     */
    func pause()
    
    func resume()
    
    func seek(to time: CMTime)
    
    /**
     Prepare for playing the next entry.      
    */
    func prepareNext(_ config: PlayerConfig) -> Bool

    /**
     Load the entry that was prepared with prepareNext(), without waiting for the current entry to end.
     */
    func loadNext() -> Bool
    
    /**
     Release player resources.
    */
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

