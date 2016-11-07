//
//  Player.swift
//  PlayKit
//
//  Created by Noam Tamim on 28/08/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

import UIKit


public protocol Player {
    /**
     Prepare for playing an entry. If `config.autoPlay` is true, the entry will automatically
     play when it's ready.
     */
    func load(_ config: PlayerConfig) -> Bool
    
    /**
     Apply properties from the `config`. 
     */
    func apply(_ config: PlayerConfig) -> Bool
    
    /**
     Should playback start when ready? 
     If set to true after entry is loaded, this will start playback.
     If set to false while entry is playing, this will pause playback.
     */
    var autoPlay: Bool { get set }
    
    /**
     Convenience method for setting shouldPlayWhenReady to true.
     */
    func play()
    
    /**
     Convenience method for setting shouldPlayWhenReady to false.
     */
    func pause()
    
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
     Get the player's View component.
    */
    var view: UIView { get }
    
    /**
     Get/set the current player position.
    */
    var currentTime: TimeInterval { get set }
    
    /**
     Release player resources.
    */
    func release()
    
    func addBoundaryTimeObserver(origin: Origin, offset: TimeInterval, wait: Bool, observer: TimeObserver)
}

public protocol TimeObserver {
    func timeReached(player: Player, origin: Origin, offset: TimeInterval)
}

public enum Origin {
    case start
    case end
}

