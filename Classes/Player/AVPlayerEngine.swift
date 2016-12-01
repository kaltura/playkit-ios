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

class AVPlayerEngine : AVPlayer, PlayerEngine {
    
    private var avPlayerLayer: AVPlayerLayer!
    
    private var _view: PlayerView!
    private var currentState: PlayerState = PlayerState.idle
    var delegate: PlayerEngineDelegate?
    
    // AVPlayerItem.currentTime() and the AVPlayerItem.timebase's rate are not KVO observable. We check their values regularly using this timer.
    private let nonObservablePropertiesUpdateTimer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.main)
   
    public var view: UIView! {
        get {
            PKLog.trace("get player view: \(_view)")
            return _view
        }
    }
    
    public var currentPosition: Double {
        get {
            PKLog.trace("get currentPosition: \(self.currentTime())")
            return CMTimeGetSeconds(self.currentTime())
        }
        set {
            PKLog.trace("set currentPosition: \(currentPosition)")
            let newTime = CMTimeMakeWithSeconds(newValue, 1)
            super.seek(to: newTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
            
            guard let _ = delegate?.player(changedEvent: PlayerEvents.seeking()) else {
                PKLog.trace("player changedEvent is not implimented")
                return
            }
        }
    }
    
    public var duration: Double {
        guard let currentItem = self.currentItem else { return 0.0 }
        PKLog.trace("get duration: \(self.currentItem?.duration)")
        return CMTimeGetSeconds(self.currentItem!.duration)
    }
    
    /// TODO::
    //private var asset: PlayerAsset?
    
    public override init() {
        PKLog.trace("init AVPlayer")
        super.init()
        
        avPlayerLayer = AVPlayerLayer(player: self)
        _view = PlayerView(playerLayer: avPlayerLayer)
    }
    
    private func setupNonObservablePropertiesUpdateTimer() {
        PKLog.trace("setupNonObservablePropertiesUpdateTimer")
        
        nonObservablePropertiesUpdateTimer.setEventHandler { [weak self] in
            self?.updateNonObservableProperties()
        }
        nonObservablePropertiesUpdateTimer.scheduleRepeating(deadline: DispatchTime.now(),
                                                             interval: DispatchTimeInterval.milliseconds(50))
    }
    
    /**
     Convenience method for setting shouldPlayWhenReady to true.
     */
    public func load() {
        PKLog.trace("load player")
    }
    
    public override func pause() {
        // autoPlay = false
        
        if self.rate == 1.0 {
            // Playing, so pause.
            PKLog.trace("pause player")
            super.pause()
        }
    }
    
    public override func play() {
        // autoPlay = true
        
        if self.rate != 1.0 {
            PKLog.trace("play player")
            
            guard let _ = delegate?.player(changedEvent: PlayerEvents.play()) else {
                NSLog("player changedState is not implimented")
                return
            }
            
            super.play()
        }
    }
    
    func prepareNext(_ config: PlayerConfig) -> Bool {
        if let sources = config.mediaEntry?.sources {
            if sources.count > 0 {
                if let contentUrl = sources[0].contentUrl {
                    PKLog.trace("prepareNext item for player")
                    self.replaceCurrentItem(with: AVPlayerItem(url: contentUrl))
                    self.nonObservablePropertiesUpdateTimer.suspend()
                    self.setupNonObservablePropertiesUpdateTimer()
                    self.addObservers()
                }
            }
        }
        return true
    }
    
    func loadNext() -> Bool {
        PKLog.trace("loadNext item for player")
        return false
    }
    
    func destroy() {
        PKLog.trace("destory player")
        self.removeObservers()
    }
    
    @available(iOS 9.0, *)
    func createPiPController(with delegate: AVPictureInPictureControllerDelegate) -> AVPictureInPictureController?{
        let pip = AVPictureInPictureController(playerLayer: avPlayerLayer)
        pip?.delegate = delegate
        return pip
    }
    
    // MARK: - KVO Observation
    
    // KVO player keys
    private let PlayerTracksKey = "tracks"
    private let PlayerPlayableKey = "playable"
    private let PlayerDurationKey = "duration"
    private let PlayerRateKey = "rate"
    
    // KVO player item keys
    private let PlayerStatusKey = "status"
    private let PlayerEmptyBufferKey = "playbackBufferEmpty"
    private let PlayerKeepUpKey = "playbackLikelyToKeepUp"
    private let PlayerCurrentItemKey = "currentItem"
    
    // - Observers
    func addObservers() {
        PKLog.trace("addObservers")
        self.addObserver(self, forKeyPath: PlayerRateKey, options: [], context: nil)
        
        self.currentItem?.addObserver(self, forKeyPath: PlayerEmptyBufferKey, options: [], context: nil)
        self.currentItem?.addObserver(self, forKeyPath: PlayerStatusKey, options: [], context: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerFailed(notification:)), name: NSNotification.Name.AVPlayerItemFailedToPlayToEndTime, object: self.currentItem)
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerPlayedToEnd(notification:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.currentItem)
    }
    
    func removeObservers() {
        do {
            try
                PKLog.trace("removeObservers")
                self.removeObserver(self, forKeyPath: self.PlayerRateKey)
            
            self.currentItem?.removeObserver(self, forKeyPath: self.PlayerEmptyBufferKey)
            self.currentItem?.removeObserver(self, forKeyPath: self.PlayerStatusKey)
            
            NotificationCenter.default.removeObserver(self)
            
            
        } catch  {
            PKLog.trace("can't removeObservers")
        }
    }
    
    public func playerFailed(notification: NSNotification) {
        let newState = PlayerState.error
        self.postStateChange(newState: newState, oldState: self.currentState)
        self.currentState = newState
        
        guard let _ = delegate?.player(changedEvent: PlayerEvents.error()) else {
            PKLog.trace("player changedEvent is not implimented")
            return
        }
    }
    
    public func playerPlayedToEnd(notification: NSNotification) {
            let newState = PlayerState.idle
            self.postStateChange(newState: newState, oldState: self.currentState)
            self.currentState = newState
            
            guard let _ = delegate?.player(changedEvent: PlayerEvents.ended()) else {
                PKLog.trace("player changedEvent is not implimented")
                return
            
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        var event: PKEvent? = nil
        
        if keyPath == PlayerKeepUpKey {
            if let item = self.currentItem {
                let newState = PlayerState.ready
                self.postStateChange(newState: newState, oldState: self.currentState)
                self.currentState = newState
            }
        } else if keyPath == PlayerEmptyBufferKey {
            if let item = self.currentItem {
                let newState = PlayerState.idle
                self.postStateChange(newState: newState, oldState: self.currentState)
                self.currentState = newState
            }
        } else if keyPath == #keyPath(currentItem.duration) {
            event = PlayerEvents.durationChange(duration: CMTimeGetSeconds((self.currentItem?.duration)!))
        } else if keyPath == #keyPath(rate) {
            if rate == 1.0 {
                nonObservablePropertiesUpdateTimer.resume()
            } else {
                nonObservablePropertiesUpdateTimer.suspend()
                event = PlayerEvents.pause()
            }
        } else if keyPath == PlayerStatusKey {
            if currentItem?.status == .readyToPlay {
                let newState = PlayerState.ready
                self.postStateChange(newState: newState, oldState: self.currentState)
                self.currentState = newState
                
                event = PlayerEvents.canPlay()
            } else if currentItem?.status == .failed {
                let newState = PlayerState.error
                self.postStateChange(newState: newState, oldState: self.currentState)
                self.currentState = newState
                
                event = PlayerEvents.error()
            }
        } else if keyPath == PlayerCurrentItemKey {
            let newState = PlayerState.idle
            self.postStateChange(newState: newState, oldState: self.currentState)
            self.currentState = newState
        }
        
        PKLog.trace("EventChanged::\(event)")
        
        if event == nil {
            event = PlayerEvents.seeking()
        }
        guard let _ = delegate?.player(changedEvent: event!) else {
            PKLog.trace("player changedState is not implimented")
            return
        }
    }
    
    private func postStateChange(newState: PlayerState, oldState: PlayerState) {
        PKLog.trace("stateChanged:: new:\(newState) old:\(oldState)")
        let event: PKEvent = PlayerEvents.stateChanged(newState: newState, oldState: oldState)
        
        guard let _ = delegate?.player(changedEvent: event) else {
            PKLog.trace("state is not valid \(event)")
            return
        }
    }
    
    private func updateNonObservableProperties() {
        if let timebaseRate: Float64 = CMTimebaseGetRate(self.currentItem!.timebase!){
            if timebaseRate == 1.0 {
                guard let _ = delegate?.player(changedEvent: PlayerEvents.playing()) else {
                    PKLog.trace("player changedState is not implimented")
                    return
                }
                nonObservablePropertiesUpdateTimer.suspend()
            }
            
            PKLog.trace("timebaseRate:: \(timebaseRate)")
        }
    }
}
