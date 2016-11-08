//
//  PlayerEngine.swift
//  Pods
//
//  Created by Eliza Sapir on 06/11/2016.
//
//

import Foundation

public protocol PlayerEngine {
    /**
     Should playback start when ready?
     If set to true after entry is loaded, this will start playback.
     If set to false while entry is playing, this will pause playback.
     */
    var autoPlay: Bool { get set }
    
    /**
     Convenience method for setting shouldPlayWhenReady to true.
     */
    func load()
    
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
    var view: UIView? { get }
    
    /**
     Get/set the current player position.
     */
    var currentPosition: TimeInterval { get set }
    
    /**
     Release player resources.
     */
    func release()
    
    var layer: CALayer! { get }
    
    func addBoundaryTimeObserver(origin: Origin, offset: TimeInterval, wait: Bool, observer: TimeObserver)
}
