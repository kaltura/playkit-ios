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

public protocol PlayerDelegate: class {
    func playerShouldPlayAd(_ player: Player) -> Bool
    func player(_ player: Player, failedWith error: String)
}

public protocol Player {
    
    var delegate: PlayerDelegate? { get set }
        
    /**
     Get the player's layer component.
     */
    var view: UIView! { get }
    
    /**
     Get/set the current player position.
     */
    var currentTime: TimeInterval? { get set }
    
    /**
     Prepare for playing an entry. If `config.autoPlay` is true, the entry will automatically
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
     Prepare for playing the next entry. If `config.shouldAutoPlay` is true, the entry will automatically
     play when it's ready and the current entry is ended.
     
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
    
    @available(iOS 9.0, *)
    func createPiPController(with delegate: AVPictureInPictureControllerDelegate) -> AVPictureInPictureController?
}

protocol PlayerDecoratorProvider {
    func getPlayerDecorator() -> PlayerDecoratorBase?
}
