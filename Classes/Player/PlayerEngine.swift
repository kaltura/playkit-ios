//
//  PlayerEngine.swift
//  Pods
//
//  Created by Eliza Sapir on 06/11/2016.
//
//

import Foundation
import AVFoundation
import AVKit

public protocol PlayerEngineDelegate: class {
    
    func player(changedState: PKEvent)
    func player(encounteredError: NSError)
}

public protocol PlayerEngine {
    weak var delegate: PlayerEngineDelegate? {get set}
    
    /**
     Get the player's view component.
     */
    var view: UIView! { get }
    
    /**
     Get/set the current player position.
     */
    var currentPosition: TimeInterval { get set }
    
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
    
    func addBoundaryTimeObserver(origin: Origin, offset: TimeInterval, wait: Bool, observer: TimeObserver)
    
    @available(iOS 9.0, *)
    func createPiPController(with delegate: AVPictureInPictureControllerDelegate) -> AVPictureInPictureController?
}
