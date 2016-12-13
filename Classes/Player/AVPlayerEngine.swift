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

class AVPlayerEngine : AVPlayer {
    
    // MARK: Player Properties
    
    // Attempt load and test these asset keys before playing.
    let assetKeysRequiredToPlay = [
        "playable", 
        "tracks",
        "hasProtectedContent",
    ]
    
    private var avPlayerLayer: AVPlayerLayer!
    
    private var _view: PlayerView!
    private var currentState: PlayerState = PlayerState.idle
    private var isObserved: Bool = false
    private var tracksManager = TracksManager()
    
//  AVPlayerItem.currentTime() and the AVPlayerItem.timebase's rate are not KVO observable. We check their values regularly using this timer.
    private let nonObservablePropertiesUpdateTimer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.main)
    
    public var onEventBlock: ((PKEvent)->Void)?
    
    public var view: UIView! {
        get {
            PKLog.trace("get player view: \(_view)")
            return _view
        }
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
            return CMTimeGetSeconds(self.currentTime())
        }
        set {
            PKLog.trace("set currentPosition: \(currentPosition)")
            let newTime = CMTimeMakeWithSeconds(newValue, 1)
            super.seek(to: newTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero) { (isSeeked: Bool) in
                if isSeeked {
                    self.postEvent(event: PlayerEvents.seeked())
                    PKLog.trace("seeked")
                } else {
                    PKLog.error("seek faild")
                }
            }
            
            self.postEvent(event: PlayerEvents.seeking())
        }
    }
    
    public var duration: Double {
        guard let currentItem = self.currentItem else { return 0.0 }
        PKLog.trace("get duration: \(self.currentItem?.duration)")
        return CMTimeGetSeconds(self.currentItem!.duration)
    }
    
    public var isPlaying: Bool {
        guard let currentItem = self.currentItem else {
            PKLog.error("current item is empty")
            return false
        }
        
        if self.rate > 0 {
            if let timebase = currentItem.timebase {
                if let timebaseRate: Float64 = CMTimebaseGetRate(timebase){
                    if timebaseRate > 0 {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    // MARK: Player Methods
    
    public override init() {
        PKLog.trace("init AVPlayer")
        super.init()
        
        avPlayerLayer = AVPlayerLayer(player: self)
        _view = PlayerView(playerLayer: avPlayerLayer)
        self.onEventBlock = nil
    }
    
    deinit {
        self.destroy()
    }
    
    private func setupNonObservablePropertiesUpdateTimer() {
        PKLog.trace("setupNonObservablePropertiesUpdateTimer")
        
        nonObservablePropertiesUpdateTimer.setEventHandler { [weak self] in
            self?.updateNonObservableProperties()
        }
        nonObservablePropertiesUpdateTimer.scheduleRepeating(deadline: DispatchTime.now(), interval: DispatchTimeInterval.milliseconds(50))
    }
    
    /**
     Convenience method for setting shouldPlayWhenReady to true.
     */
    public func load() {
        PKLog.trace("load player")
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
            
            self.postEvent(event: PlayerEvents.play())
            super.play()
        }
    }
    
    func destroy() {
        PKLog.trace("destory player")
        self.nonObservablePropertiesUpdateTimer.suspend()
        self.removeObservers()
        avPlayerLayer = nil
        _view = nil
        onEventBlock = nil
    }
    
    @available(iOS 9.0, *)
    func createPiPController(with delegate: AVPictureInPictureControllerDelegate) -> AVPictureInPictureController?{
        let pip = AVPictureInPictureController(playerLayer: avPlayerLayer)
        pip?.delegate = delegate
        return pip
    }
    
    // MARK: - Asset Loading
    
    func asynchronouslyLoadURLAsset(_ newAsset: AVAsset) {
        /*
         Using AVAsset now runs the risk of blocking the current thread (the
         main UI thread) whilst I/O happens to populate the properties. It's
         prudent to defer our work until the properties we need have been loaded.
         */
        newAsset.loadValuesAsynchronously(forKeys: self.assetKeysRequiredToPlay) {
            /*
             The asset invokes its completion handler on an arbitrary queue.
             To avoid multiple threads using our internal state at the same time
             we'll elect to use the main thread at all times, let's dispatch
             our handler to the main queue.
             */
            DispatchQueue.main.async {
                /*
                 `self.asset` has already changed! No point continuing because
                 another `newAsset` will come along in a moment.
                 */
                guard newAsset == self.asset else { return }
                
                /*
                 Test whether the values of each of the keys we need have been
                 successfully loaded.
                 */
                for key in self.assetKeysRequiredToPlay {
                    var error: NSError?
                    
                    if newAsset.statusOfValue(forKey: key, error: &error) == .failed {
                        let stringFormat = NSLocalizedString("error.asset_key_%@_failed.description", comment: "Can't use this AVAsset because one of it's keys failed to load")
                        
                        let message = String.localizedStringWithFormat(stringFormat, key)
                        
                        PKLog.error(message)
                        
                        return
                    }
                }
                
                // We can't play this asset.
                if !newAsset.isPlayable {
                    let message = NSLocalizedString("error.asset_not_playable.description", comment: "Can't use this AVAsset because it isn't playable")
                    
                    PKLog.error(message)
                    
                    return
                }
                
                /*
                 We can play this asset. Create a new `AVPlayerItem` and make
                 it our player's current item.
                 */
                self.replaceCurrentItem(with: AVPlayerItem(asset: newAsset))
                self.removeObservers()
                self.addObservers()
            }
        }
    }
    
    // MARK: - KVO Observation
    
    // An array of key paths for the properties we want to observe.
    private let observedKeyPaths = [
        #keyPath(rate),
        #keyPath(currentItem.status),
        #keyPath(currentItem),
        #keyPath(currentItem.playbackLikelyToKeepUp),
        #keyPath(currentItem.playbackBufferEmpty),
        #keyPath(currentItem.duration)
    ]
    
    private var observerContext = 0
    
    // - Observers
    func addObservers() {
        PKLog.trace("addObservers")
        
        self.isObserved = true
        // Register observers for the properties we want to display.
        for keyPath in observedKeyPaths {
            addObserver(self, forKeyPath: keyPath, options: [.new, .initial], context: &observerContext)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerFailed(notification:)), name: NSNotification.Name.AVPlayerItemFailedToPlayToEndTime, object: self.currentItem)
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerPlayedToEnd(notification:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.currentItem)
    }
    
    func removeObservers() {
        if !self.isObserved {
            return
        }
        
        PKLog.trace("removeObservers")
        
        // Un-register observers
        for keyPath in observedKeyPaths {
            removeObserver(self, forKeyPath: keyPath, context: &observerContext)
        }
        
        NotificationCenter.default.removeObserver(self)
    }
    
    public func playerFailed(notification: NSNotification) {
        let newState = PlayerState.error
        self.postStateChange(newState: newState, oldState: self.currentState)
        self.currentState = newState
        
        self.postEvent(event: PlayerEvents.error())
    }
    
    public func playerPlayedToEnd(notification: NSNotification) {
        let newState = PlayerState.idle
        self.postStateChange(newState: newState, oldState: self.currentState)
        self.currentState = newState
        
        self.postEvent(event: PlayerEvents.ended())
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        PKLog.debug("observeValue:: onEvent/onState")
        
        guard context == &observerContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        guard let keyPath = keyPath else {
            return
        }
        
        PKLog.trace("keyPath:: \(keyPath)")

        var event: PKEvent? = nil
        
        switch keyPath {
        case #keyPath(currentItem.playbackLikelyToKeepUp):
            self.handleLikelyToKeepUp()
        case #keyPath(currentItem.playbackBufferEmpty):
            self.handleBufferEmptyChange()
        case #keyPath(currentItem.duration):
            event = PlayerEvents.durationChange(duration: CMTimeGetSeconds((self.currentItem?.duration)!))
        case #keyPath(rate):
            if rate > 0 {
                nonObservablePropertiesUpdateTimer.resume()
            } else {
                event = PlayerEvents.pause()
            }
        case #keyPath(currentItem.status):
            event = self.handleStatusChange()
        case #keyPath(currentItem):
            self.handleItemChange()
            
        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }

        self.postEvent(event: event)
    }
    
    private func handleLikelyToKeepUp() {
        if let item = self.currentItem {
            let newState = PlayerState.ready
            self.postStateChange(newState: newState, oldState: self.currentState)
            self.currentState = newState
        }
    }
    
    private func handleBufferEmptyChange() {
        if let item = self.currentItem {
            let newState = PlayerState.idle
            self.postStateChange(newState: newState, oldState: self.currentState)
            self.currentState = newState
        }
    }
    
    private func handleStatusChange() -> PKEvent? {
        var event: PKEvent? = nil
        
        if currentItem?.status == .readyToPlay {
            self.setupNonObservablePropertiesUpdateTimer()
            
            let newState = PlayerState.ready
            self.postEvent(event: PlayerEvents.loadedMetadata())
            
            self.tracksManager.handleTracks(item: self.currentItem, block: { (tracks: PKTracks) in
                self.postEvent(event: PlayerEvents.tracksAvailable(tracks: tracks))
            })
                
            self.postStateChange(newState: newState, oldState: self.currentState)
            self.currentState = newState
            
            event = PlayerEvents.canPlay()
        } else if currentItem?.status == .failed {
            let newState = PlayerState.error
            self.postStateChange(newState: newState, oldState: self.currentState)
            self.currentState = newState
            
            event = PlayerEvents.error()
        }
        
        return event
    }
    
    private func handleItemChange() {
        let newState = PlayerState.idle
        self.postStateChange(newState: newState, oldState: self.currentState)
        self.currentState = newState
    }
    
    private func postEvent(event: PKEvent?) {
        if let currentEvent: PKEvent = event {
            PKLog.trace("onEvent:: \(currentEvent)")
            
            if let block = onEventBlock {
                block(currentEvent)
            }
        } else {
            PKLog.error("event is empty:: \(event)")
        }
    }
    
    public func selectTrack(trackId: String) {
        if let id: String = trackId {
           self.tracksManager.selectTrack(item: self.currentItem!, trackId: trackId)
        } else {
            PKLog.warning("trackId is nil")
        }
    }
    
    private func postStateChange(newState: PlayerState, oldState: PlayerState) {
        PKLog.trace("stateChanged:: new:\(newState) old:\(oldState)")
        let stateChangedEvent: PKEvent = PlayerEvents.stateChanged(newState: newState, oldState: oldState)
        
        self.postEvent(event: stateChangedEvent)
    }
    
    // MARK: - Non Observable Properties
    private func updateNonObservableProperties() {
        if let currItem = self.currentItem {
            if let timebase = currItem.timebase {
                if let timebaseRate: Float64 = CMTimebaseGetRate(timebase){
                    if timebaseRate > 0 {
                        nonObservablePropertiesUpdateTimer.suspend()
                        
                        self.postEvent(event: PlayerEvents.playing())
                    }
                    
                    PKLog.trace("timebaseRate:: \(timebaseRate)")
                }
            }
        }
    }
}
