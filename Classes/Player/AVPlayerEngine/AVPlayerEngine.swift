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
    private var isDestroyed = false
    
    var lastBitrate: Double = 0
    var isObserved: Bool = false
    var currentState: PlayerState = PlayerState.idle
    var tracksManager = TracksManager()
    
    /// Indicates whether the current items was played until the end.
    ///
    /// - note: Used for preventing 'pause' events to be sent after 'ended' event.
    var isPlayedToEndTime: Bool = false
    
    //  AVPlayerItem.currentTime() and the AVPlayerItem.timebase's rate are not KVO observable. We check their values regularly using this timer.
    var nonObservablePropertiesUpdateTimer: Timer?
    
    var observerContext = 0
    
    public var onEventBlock: ((PKEvent) -> Void)?
    
    public var view: UIView! {
        PKLog.trace("get player view: \(_view)")
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
            PKLog.trace("set currentPosition: \(currentPosition)")

            let newTime = rangeStart + CMTimeMakeWithSeconds(newValue, 1)
            super.seek(to: newTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero) { [unowned self] (isSeeked: Bool) in
                if isSeeked {
                    // when seeked successfully reset player reached end time indicator
                    self.isPlayedToEndTime = false
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
        self.nonObservablePropertiesUpdateTimer = nil
        
        AppStateSubject.shared.add(observer: self)
    }
    
    deinit {
        if !isDestroyed {
            self.destroy()
        }
    }
    
    func startOrResumeNonObservablePropertiesUpdateTimer() {
        PKLog.debug("setupNonObservablePropertiesUpdateTimer")
        self.nonObservablePropertiesUpdateTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.updateNonObservableProperties), userInfo: nil, repeats: true)
    }
    
    public override func pause() {
        if self.rate > 0 {
            // Playing, so pause.
            PKLog.trace("pause player")
            super.pause()
        }
    }
    
    public override func play() {
        if self.rate == 0 {
            PKLog.trace("play player")
            self.post(event: PlayerEvent.Play())
            super.play()
        }
    }
    
    func destroy() {
        PKLog.trace("destory player")
        self.nonObservablePropertiesUpdateTimer?.invalidate()
        self.nonObservablePropertiesUpdateTimer = nil
        self.removeObservers()
        self.avPlayerLayer = nil
        self._view = nil
        self.onEventBlock = nil
        // removes app state observer
        AppStateSubject.shared.remove(observer: self)
        self.replaceCurrentItem(with: nil)
        self.isDestroyed = true
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
        PKLog.debug("onEvent:: \(event)")
        onEventBlock?(event)
    }
    
    func postStateChange(newState: PlayerState, oldState: PlayerState) {
        PKLog.debug("stateChanged:: new:\(newState) old:\(oldState)")
        let stateChangedEvent: PKEvent = PlayerEvent.StateChanged(newState: newState, oldState: oldState)
        self.post(event: stateChangedEvent)
    }
    
    // MARK: - Non Observable Properties
    @objc func updateNonObservableProperties() {
        guard let timebase = self.currentItem?.timebase else { return }
        let timebaseRate = CMTimebaseGetRate(timebase)
        if timebaseRate > 0 {
            self.nonObservablePropertiesUpdateTimer?.invalidate()
            self.post(event: PlayerEvent.Playing())
        }
        PKLog.debug("timebaseRate:: \(timebaseRate)")
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
