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

/// `AVPlayerEngineError` represents player engine errors.
enum PlayerError: PKError {
    
    case failedToLoadAssetFromKeys(rootError: NSError?)
    case assetNotPlayable
    case failedToPlayToEndTime(rootError: NSError)
    case playerItemErrorLogEvent(errorLogEvent: AVPlayerItemErrorLogEvent)
    
    static let Domain = PKErrorDomain.Player
    
    var code: Int {
        switch self {
        case .failedToLoadAssetFromKeys: return 1000
        case .assetNotPlayable: return 1001
        case .failedToPlayToEndTime: return 1002
        case .playerItemErrorLogEvent: return 1003
        }
    }
    
    var errorDescription: String {
        switch self {
        case .failedToLoadAssetFromKeys: return "Can't use this AVAsset because one of it's keys failed to load"
        case .assetNotPlayable: return "Can't use this AVAsset because it isn't playable"
        case .failedToPlayToEndTime: return "Item failed to play to its end time"
        case .playerItemErrorLogEvent(let errorLogEvent): return errorLogEvent.errorComment ?? ""
        }
    }
    
    var userInfo: [String: Any] {
        switch self {
        case .failedToLoadAssetFromKeys(let rootError): return [RootErrorKey : rootError]
        case .assetNotPlayable: return [:]
        case .failedToPlayToEndTime(let rootError): return [RootErrorKey : rootError]
        case .playerItemErrorLogEvent(let errorLogEvent):
            return [
                RootCodeKey : errorLogEvent.errorStatusCode,
                RootDomainKey : errorLogEvent.errorDomain
            ]
        }
    }
}

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
    private var currentState: PlayerState = PlayerState.idle
    private var isObserved: Bool = false
    private var tracksManager = TracksManager()
    private var lastBitrate: Double = 0
    private var isDestroyed = false
    
    /// Indicates whether the current items was played until the end.
    ///
    /// - note: Used for preventing 'pause' events to be sent after 'ended' event.
    private var isPlayedToEndTime: Bool = false
    
    //  AVPlayerItem.currentTime() and the AVPlayerItem.timebase's rate are not KVO observable. We check their values regularly using this timer.
    private var nonObservablePropertiesUpdateTimer: Timer?
    
    public var onEventBlock: ((PKEvent)->Void)?
    
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
    
    private func startOrResumeNonObservablePropertiesUpdateTimer() {
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
        self.nonObservablePropertiesUpdateTimer == nil
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
                        self.post(event: PlayerEvent.Error(nsError: PlayerError.failedToLoadAssetFromKeys(rootError: error).asNSError))
                        
                        return
                    }
                }
                
                // We can't play this asset.
                if !newAsset.isPlayable {
                    let message = NSLocalizedString("error.asset_not_playable.description", comment: "Can't use this AVAsset because it isn't playable")
                    
                    PKLog.error(message)
                    self.post(event: PlayerEvent.Error(nsError: PlayerError.assetNotPlayable.asNSError))
                    
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerFailed(notification:)), name: .AVPlayerItemFailedToPlayToEndTime, object: self.currentItem)
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerPlayedToEnd(notification:)), name: .AVPlayerItemDidPlayToEndTime, object: self.currentItem)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onAccessLogEntryNotification), name: .AVPlayerItemNewAccessLogEntry, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onErrorLogEntryNotification), name: .AVPlayerItemNewErrorLogEntry, object: nil)
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
        
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemFailedToPlayToEndTime, object: nil)
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemNewAccessLogEntry, object: nil)
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemNewErrorLogEntry, object: nil)
    }
    
    func onAccessLogEntryNotification(notification: Notification) {
        if let item = notification.object as? AVPlayerItem, let accessLog = item.accessLog(), let lastEvent = accessLog.events.last {
            if #available(iOS 10.0, *) {
                PKLog.debug("event log:\n event log: averageAudioBitrate - \(lastEvent.averageAudioBitrate)\n event log: averageVideoBitrate - \(lastEvent.averageVideoBitrate)\n event log: indicatedAverageBitrate - \(lastEvent.indicatedAverageBitrate)\n event log: indicatedBitrate - \(lastEvent.indicatedBitrate)\n event log: observedBitrate - \(lastEvent.observedBitrate)\n event log: observedMaxBitrate - \(lastEvent.observedMaxBitrate)\n event log: observedMinBitrate - \(lastEvent.observedMinBitrate)\n event log: switchBitrate - \(lastEvent.switchBitrate)")
            }
            
            if lastEvent.indicatedBitrate != self.lastBitrate {
                self.lastBitrate = lastEvent.indicatedBitrate
                PKLog.trace("currentBitrate:: \(self.lastBitrate)")
                self.post(event: PlayerEvent.PlaybackParamsUpdated(currentBitrate: self.lastBitrate))
            }
        }
    }
    
    func onErrorLogEntryNotification(notification: Notification) {
        guard let playerItem = notification.object as? AVPlayerItem, let errorLog = playerItem.errorLog(), let lastEvent = errorLog.events.last else { return }
        PKLog.error("error description: \(lastEvent.errorComment), error domain: \(lastEvent.errorDomain), error code: \(lastEvent.errorStatusCode)")
        self.post(event: PlayerEvent.Error(nsError: PlayerError.playerItemErrorLogEvent(errorLogEvent: lastEvent).asNSError))
    }
    
    public func playerFailed(notification: NSNotification) {
        let newState = PlayerState.error
        self.postStateChange(newState: newState, oldState: self.currentState)
        self.currentState = newState
        
        if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? NSError {
            self.post(event: PlayerEvent.Error(nsError: PlayerError.failedToPlayToEndTime(rootError: error).asNSError))
        } else {
            self.post(event: PlayerEvent.Error())
        }
    }
    
    public func playerPlayedToEnd(notification: NSNotification) {
        let newState = PlayerState.idle
        self.postStateChange(newState: newState, oldState: self.currentState)
        self.currentState = newState
        self.isPlayedToEndTime = true
        self.post(event: PlayerEvent.Ended())
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
        
        PKLog.debug("keyPath:: \(keyPath)")
        
        switch keyPath {
        case #keyPath(currentItem.playbackLikelyToKeepUp):
            self.handleLikelyToKeepUp()
        case #keyPath(currentItem.playbackBufferEmpty):
            self.handleBufferEmptyChange()
        case #keyPath(currentItem.duration):
            if let currentItem = self.currentItem {
                self.post(event: PlayerEvent.DurationChanged(duration: CMTimeGetSeconds(currentItem.duration)))
            }
        case #keyPath(rate):
            self.handleRate()
        case #keyPath(currentItem.status):
            self.handleStatusChange()
        case #keyPath(currentItem):
            self.handleItemChange()
        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    private func handleLikelyToKeepUp() {
        if self.currentItem != nil {
            let newState = PlayerState.ready
            self.postStateChange(newState: newState, oldState: self.currentState)
            self.currentState = newState
        }
    }
    
    private func handleBufferEmptyChange() {
        if self.currentItem != nil {
            let newState = PlayerState.idle
            self.postStateChange(newState: newState, oldState: self.currentState)
            self.currentState = newState
        }
    }
    
    /// Handles change in player rate
    ///
    /// - Returns: The event to post, rate <= 0 means pause event.
    private func handleRate() {
        if rate > 0 {
            self.startOrResumeNonObservablePropertiesUpdateTimer()
        } else {
            self.nonObservablePropertiesUpdateTimer?.invalidate()
            // we don't want pause events to be sent when current item reached end.
            if !isPlayedToEndTime {
                self.post(event: PlayerEvent.Pause())
            }
        }
    }
    
    private func handleStatusChange() {
        if currentItem?.status == .readyToPlay {
            let newState = PlayerState.ready
            self.post(event: PlayerEvent.LoadedMetadata())
            
            if self.startPosition > 0 {
                self.currentPosition = self.startPosition
                self.startPosition = 0
            }
            
            self.tracksManager.handleTracks(item: self.currentItem, block: { (tracks: PKTracks) in
                self.post(event: PlayerEvent.TracksAvailable(tracks: tracks))
            })
            
            self.postStateChange(newState: newState, oldState: self.currentState)
            self.currentState = newState
            
            self.post(event: PlayerEvent.CanPlay())
        } else if currentItem?.status == .failed {
            let newState = PlayerState.error
            self.postStateChange(newState: newState, oldState: self.currentState)
            self.currentState = newState
        }
    }
    
    private func handleItemChange() {
        let newState = PlayerState.idle
        self.postStateChange(newState: newState, oldState: self.currentState)
        self.currentState = newState
        // in case item changed reset player reached end time indicator
        isPlayedToEndTime = false
    }
    
    fileprivate func post(event: PKEvent) {
        if let currentEvent: PKEvent = event {
            PKLog.debug("onEvent:: \(currentEvent)")
            
            if let block = onEventBlock {
                block(currentEvent)
            }
        }
    }
    
    public func selectTrack(trackId: String) {
        if trackId.isEmpty == false {
            self.tracksManager.selectTrack(item: self.currentItem!, trackId: trackId)
        } else {
            PKLog.error("trackId is nil")
        }
    }
    
    private func postStateChange(newState: PlayerState, oldState: PlayerState) {
        PKLog.debug("stateChanged:: new:\(newState) old:\(oldState)")
        let stateChangedEvent: PKEvent = PlayerEvent.StateChanged(newState: newState, oldState: oldState)
        self.post(event: stateChangedEvent)
    }
    
    // MARK: - Non Observable Properties
    @objc private func updateNonObservableProperties() {
        if let currItem = self.currentItem {
            if let timebase = currItem.timebase {
                if let timebaseRate: Float64 = CMTimebaseGetRate(timebase){
                    if timebaseRate > 0 {
                        self.nonObservablePropertiesUpdateTimer?.invalidate()
                        
                        self.post(event: PlayerEvent.Playing())
                    }
                    PKLog.debug("timebaseRate:: \(timebaseRate)")
                }
            }
        }
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


