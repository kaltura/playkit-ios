//
//  AVPlayerEngine.swift
//  Pods
//
//  Created by Eliza Sapir on 07/11/2016.
//
//

import Foundation
import AVFoundation
import AVKit
import CoreMedia

/// An AVPlayerEngine is a controller used to manage the playback and timing of a media asset.
/// It provides the interface to control the player’s behavior such as its ability to play, pause, and seek to various points in the timeline.
class AVPlayerEngine: AVPlayer {
    
    // MARK: Player Properties
    
    // Attempt load and test these asset keys before playing.
    let assetKeysRequiredToPlay = [
        "playable",
        "tracks",
        "hasProtectedContent"
    ]
    
    private var avPlayerLayer: AVPlayerLayer!
    private var _view: PlayerView!
    
    var lastTimebaseRate: Float64 = 0
    var lastBitrate: Double = 0
    var isObserved: Bool = false
    var currentState: PlayerState = PlayerState.idle
    var tracksManager = TracksManager()
    var observerContext = 0
    
    public var onEventBlock: ((PKEvent) -> Void)?
    
    public var view: UIView! {
        PKLog.debug("get player view: \(_view)")
        return _view
    }
    
    public var asset: AVAsset? {
        didSet {
            guard let newAsset = asset else { return }
            self.asynchronouslyLoadURLAsset(newAsset)
        }
    }
    
    public var currentPosition: Double {
        get {
            PKLog.trace("get currentPosition: \(self.currentTime())")
            return CMTimeGetSeconds(self.currentTime() - rangeStart)
        }
        set {
            PKLog.debug("set currentPosition: \(currentPosition)")
            let newTime = rangeStart + CMTimeMakeWithSeconds(newValue, 1)
            super.seek(to: newTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero) { [unowned self] (isSeeked: Bool) in
                if isSeeked {
                    self.post(event: PlayerEvent.Seeked())
                    PKLog.debug("seeked")
                } else {
                    PKLog.error("seek faild")
                }
            }
            self.post(event: PlayerEvent.Seeking())
        }
    }
    
    public var startPosition: Double {
        didSet {
            PKLog.debug("set startPosition: \(startPosition)")
        }
    }
    
    public var duration: Double {
        guard let currentItem = self.currentItem else { return 0.0 }
        
        var result = CMTimeGetSeconds(currentItem.duration)
    
        if result.isNaN {
            let seekableRanges = currentItem.seekableTimeRanges
            if seekableRanges.count > 0 {
                let range = seekableRanges.last!.timeRangeValue
                result = CMTimeGetSeconds(range.duration)
            }
        }
        
        PKLog.trace("get duration: \(result)")
        return result
    }
    
    public var isPlaying: Bool {
        guard let currentItem = self.currentItem else {
            PKLog.error("current item is empty")
            return false
        }
        
        if self.rate > 0 {
            if let timebase = currentItem.timebase {
                let timebaseRate: Float64 = CMTimebaseGetRate(timebase)
                if timebaseRate > 0 {
                    return true
                }
            }
        }
        
        return false
    }
    
    public var currentAudioTrack: String? {
        if let currentItem = self.currentItem {
            return self.tracksManager.currentAudioTrack(item: currentItem)
        }
        return nil
    }
    
    public var currentTextTrack: String? {
        if let currentItem = self.currentItem {
            return self.tracksManager.currentTextTrack(item: currentItem)
        }
        return nil
    }
  
    private var rangeStart: CMTime {
        get {
            var result: CMTime = CMTimeMakeWithSeconds(0, 1)
            if let currentItem = self.currentItem {
                let seekableRanges = currentItem.seekableTimeRanges
                if seekableRanges.count > 0 {
                    result = seekableRanges.last!.timeRangeValue.start
                }
            }
            return result
        }
    }
    
    // MARK: Player Methods
    
    public override init() {
        PKLog.info("init AVPlayer")
        
        self.startPosition = 0
        
        super.init()
        
        avPlayerLayer = AVPlayerLayer(player: self)
        _view = PlayerView(playerLayer: avPlayerLayer)
        
        self.onEventBlock = nil
        
        AppStateSubject.shared.add(observer: self)
    }
    
    deinit {
        PKLog.debug("\(String(describing: type(of: self))), was deinitialized")
    }
    
    func stop() {
        PKLog.info("stop player")
        self.pause()
        self.seek(to: kCMTimeZero)
        self.replaceCurrentItem(with: nil)
    }
    
    override func pause() {
        // makes sure play/pause call is made on the main thread (calling on background thread has unpredictable behaviours)
        DispatchQueue.main.async {
            if self.rate > 0 {
                // Playing, so pause.
                PKLog.debug("pause player")
                super.pause()
            }
        }
    }
    
    override func play() {
        // makes sure play/pause call is made on the main thread (calling on background thread has unpredictable behaviours)
        DispatchQueue.main.async {
            if self.rate == 0 {
                PKLog.debug("play player")
                self.post(event: PlayerEvent.Play())
                super.play()
            }
        }
    }
    
    func destroy() {
        // make sure to call destroy on main thread synchronously. 
        // this make sure everything will be cleared without any race conditions
        DispatchQueue.main.async {
            PKLog.info("destroy player")
            self.removeObservers()
            self.avPlayerLayer = nil
            self._view = nil
            self.onEventBlock = nil
            // removes app state observer
            AppStateSubject.shared.remove(observer: self)
            self.replaceCurrentItem(with: nil)
        }
    }
    
    @available(iOS 9.0, *)
    func createPiPController(with delegate: AVPictureInPictureControllerDelegate) -> AVPictureInPictureController? {
        let pip = AVPictureInPictureController(playerLayer: avPlayerLayer)
        pip?.delegate = delegate
        return pip
    }
    
    public func selectTrack(trackId: String) {
        if trackId.isEmpty == false {
            self.tracksManager.selectTrack(item: self.currentItem!, trackId: trackId)
        } else {
            PKLog.error("trackId is nil")
        }
    }
    
    func post(event: PKEvent) {
        PKLog.trace("onEvent:: \(String(describing: event))")
        onEventBlock?(event)
    }
    
    func postStateChange(newState: PlayerState, oldState: PlayerState) {
        PKLog.debug("stateChanged:: new:\(newState) old:\(oldState)")
        let stateChangedEvent: PKEvent = PlayerEvent.StateChanged(newState: newState, oldState: oldState)
        self.post(event: stateChangedEvent)
    }
}

/************************************************************/
// MARK: - App State Handling
/************************************************************/

extension AVPlayerEngine: AppStateObservable {
 
    var observations: Set<NotificationObservation> {
        return [
            NotificationObservation(name: .UIApplicationWillTerminate) { [unowned self] in
                PKLog.debug("player: \(self)\n will terminate, destroying...")
                self.destroy()
            }
        ]
    }
}
