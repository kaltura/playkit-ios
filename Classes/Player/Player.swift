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

public enum PlayerEventType : Int {
    case ad_break_ready
    case ad_break_ended
    case ad_break_started
    case ad_all_completed
    case ad_clicked
    case ad_complete
    case ad_cuepoints_changed
    case ad_first_quartile
    case ad_loaded
    case ad_log
    case ad_midpoint
    case ad_paused
    case ad_resumed
    case ad_skipped
    case ad_started
    case ad_stream_loaded
    case ad_tapped
    case ad_third_quartile
    case ad_web_opener_will_open_external_browser
    case ad_web_opener_will_open_in_app_browser
    case ad_web_opener_did_open_in_app_browser
    case ad_web_opener_will_close_in_app_browser
    case ad_web_opener_did_close_in_app_browser
    case ad_did_progress_to_time
    case ad_did_request_pause
    case ad_did_request_resume
}

public protocol PlayerDataSource: class {
    func playerCanPlayAd(_ player: Player) -> Bool
}

public protocol PlayerDelegate: class {
    func player(_ player: Player, failedWith error: String)
    func player(_ player: Player, didReceive event: PlayerEventType, with eventData: Any?)
}

public protocol Player {
    
    var dataSource: PlayerDataSource? { get set }
    var delegate: PlayerDelegate? { get set }
    
    /**
     Get the player's layer component.
     */
    var view: UIView! { get }
    
    var playerEngine: PlayerEngine? { get }
    
    /**
     Get/set the current player position.
     */
    var currentTime: TimeInterval? { get set }
    
    /**
     Should playback start when ready?
     If set to true after entry is loaded, this will start playback.
     If set to false while entry is playing, this will pause playback.
     */
    var autoPlay: Bool? { get set }
    
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
    
    func addBoundaryTimeObserver(origin: Origin, offset: TimeInterval, wait: Bool, observer: TimeObserver)
    
    @available(iOS 9.0, *)
    func createPiPController(with delegate: AVPictureInPictureControllerDelegate) -> AVPictureInPictureController?
}

public protocol TimeObserver {
    func timeReached(player: Player, origin: Origin, offset: TimeInterval)
}

public enum Origin {
    case start
    case end
}
