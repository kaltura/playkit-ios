// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import Foundation
import AVFoundation
import AVKit

open class AVPlayerWrapper: NSObject, PlayerEngine {
    
    public var currentPlayer: AVPlayerEngine
    
    /// the asset to prepare and pass to the player engine to start buffering.
    private var assetToPrepare: AVURLAsset?
    /// the current selected media source
    fileprivate var preferredMediaSource: PKMediaSource?
    /// the current handler for the selected source
    fileprivate var assetHandler: AssetHandler?
    
    /// a semaphore to make sure prepare calling will wait till assetToPrepare it set.
    private let prepareSemaphore = DispatchSemaphore(value: 0)
    
    var settings: PKPlayerSettings? {
        didSet {
            guard let settings = self.settings else {
                PKLog.error("Settings are not set")
                return
            }
            
            settings.onChange = { [weak self] (settingsType) in
                guard let self = self else { return }
                switch settingsType {
                case .preferredPeakBitRate(let preferredPeakBitRate): 
                    self.currentPlayer.currentItem?.preferredPeakBitRate = preferredPeakBitRate
                case .preferredForwardBufferDuration(let preferredForwardBufferDuration):
                    if #available(iOS 10.0, tvOS 10.0, *) {
                        self.currentPlayer.currentItem?.preferredForwardBufferDuration = preferredForwardBufferDuration
                    }
                case .automaticallyWaitsToMinimizeStalling(let automaticallyWaitsToMinimizeStalling):
                    if #available(iOS 10.0, tvOS 10.0, *) {
                        self.currentPlayer.automaticallyWaitsToMinimizeStalling = automaticallyWaitsToMinimizeStalling
                    }
                }
            }
        }
    }
    
    public var mediaEntry: PKMediaEntry? {
        return self.mediaConfig?.mediaEntry
    }
    
    // Every player that is created should own a Reachability instance
    let reachability = PKReachability()
    var shouldRefresh: Bool = false
    
    public override init() {
        self.currentPlayer = AVPlayerEngine()
        super.init()
        
        self.currentPlayer.onEventBlock = { [weak self] event in
            guard let self = self else { return }
            PKLog.verbose("postEvent:: \(event)")
            self.onEventBlock?(event)
        }
        self.onEventBlock = nil
    }
    
    // ***************************** //
    // MARK: - PlayerEngine
    // ***************************** //
    
    public var onEventBlock: ((PKEvent) -> Void)?

    public var startPosition: TimeInterval {
        get { return self.currentPlayer.startPosition }
        set { self.currentPlayer.startPosition = newValue }
    }
    
    public var currentPosition: TimeInterval {
        get { return self.currentPlayer.currentPosition }
        set { self.currentPlayer.currentPosition = newValue }
    }
    
    public  var mediaConfig: MediaConfig?
    
    public var playbackType: String? {
        return self.currentPlayer.playbackType
    }
    
    open func loadMedia(from mediaSource: PKMediaSource?, handler: AssetHandler) {
        guard let mediaSrc = mediaSource else {
            PKLog.error("Media Source is empty")
            return
        }
        
        handler.build(from: mediaSrc) { error, asset in
            if asset != nil {
                self.assetToPrepare = asset
            }
            // send signal when assetToPrepare is set
            self.prepareSemaphore.signal()
        }
    }
    
    public func playFromLiveEdge() {
        if #available(iOS 10.0, tvOS 10.0, *), let shouldPlayImmediately = settings?.shouldPlayImmediately, shouldPlayImmediately == true {
            self.currentPlayer.playFromLiveEdgeImmediately(atRate: 1.0)
        } else {
            self.currentPlayer.playFromLiveEdge()
        }
    }
    
    public func updateTextTrackStyling(_ textTrackStyling: PKTextTrackStyling) {
        currentPlayer.updateTextTrackStyling(textTrackStyling)
    }
    
    // ***************************** //
    // MARK: - BasicPlayer
    // ***************************** //
    
    public var duration: Double {
        return self.currentPlayer.duration
    }
    
    public var currentState: PlayerState {
        return self.currentPlayer.currentState
    }
    
    public var isPlaying: Bool {
        return self.currentPlayer.isPlaying
    }
    
    open weak var view: PlayerView? {
        get {
            return self.currentPlayer.view
        }
        set {
            self.currentPlayer.view = newValue
        }
    }
    
    public var currentTime: TimeInterval {
        get { return self.currentPlayer.currentPosition }
        set { self.currentPlayer.currentPosition = newValue }
    }
    
    public var currentProgramTime: Date? {
        return self.currentPlayer.currentItem?.currentDate()
    }
    
    public var currentAudioTrack: String? {
        return self.currentPlayer.currentAudioTrack
    }
    
    public var currentTextTrack: String? {
        return self.currentPlayer.currentTextTrack
    }
    
    public var rate: Float {
        get {
            return self.currentPlayer.rate
        }
        set {
            self.currentPlayer.rate = newValue
        }
    }
    
    public var volume: Float {
        get {
            return self.currentPlayer.volume
        }
        set {
            self.currentPlayer.volume = newValue
        }
    }
    
    public var loadedTimeRanges: [PKTimeRange]? {
        return self.currentPlayer.currentItem?.loadedTimeRanges.map { PKTimeRange(timeRange: $0.timeRangeValue) }
    }
    
    public func play() {
        if #available(iOS 10.0, tvOS 10.0, *), let shouldPlayImmediately = settings?.shouldPlayImmediately, shouldPlayImmediately == true {
            self.currentPlayer.playImmediately(atRate: 1.0)
        } else {
            self.currentPlayer.play()
        }
    }
    
    public func pause() {
        self.currentPlayer.pause()
    }
    
    public func resume() {
        self.currentPlayer.play()
    }
    
    public func stop() {
        self.currentPlayer.stop()
    }
    
    public func replay() {
        self.currentPlayer.replay()
    }
    
    public func seek(to time: TimeInterval) {
        self.currentPlayer.currentPosition = time
    }
    
    public func selectTrack(trackId: String) {
        self.currentPlayer.selectTrack(trackId: trackId)
    }
    
    open func destroy() {
        self.currentPlayer.destroy()
        self.removeAssetRefreshObservers()
    }
    
    public func prepare(_ mediaConfig: MediaConfig) {
        // set background thread to make sure main thread is not stuck while waiting
        DispatchQueue.global().async {
            // wait till assetToPrepare is set
            self.prepareSemaphore.wait()
            
            guard let assetToPrepare = self.assetToPrepare else { return }
            
            if let startTime = self.mediaConfig?.startTime {
                self.currentPlayer.startPosition = startTime
            }
            
            guard let settings = self.settings else {
                PKLog.error("Settings are not set")
                return
            }
            
            self.currentPlayer.usesExternalPlaybackWhileExternalScreenIsActive = settings.allowFairPlayOnExternalScreens
            
            if #available(iOS 10.0, tvOS 10.0, *) {
                self.currentPlayer.automaticallyWaitsToMinimizeStalling = settings.network.automaticallyWaitsToMinimizeStalling
            }
            
            let asset = PKAsset(avAsset: assetToPrepare, playerSettings: settings, autoBuffer: settings.network.autoBuffer)
            self.currentPlayer.asset = asset
            
            if DRMSupport.widevineClassicHandler != nil {
                self.removeAssetRefreshObservers()
                self.addAssetRefreshObservers()
            }
        }
    }
    
    public func startBuffering() {
        currentPlayer.shouldStartBuffering = true
    }
}

// ********************************************************** //
// MARK: - Reachability & Application States Handling
// ********************************************************** //

extension AVPlayerWrapper {
    
    private func shouldRefreshAsset() {
        guard let preferredMediaSource = self.preferredMediaSource,
            let refreshableHandler = assetHandler as? RefreshableAssetHandler else { return }
        
        refreshableHandler.shouldRefreshAsset(mediaSource: preferredMediaSource) { [weak self] (shouldRefresh) in
            guard let self = self else { return }
            if shouldRefresh {
                self.shouldRefresh = true
            }
        }
    }
    
    private func refreshAsset() {
        guard let preferredMediaSource = self.preferredMediaSource,
            let refreshableHandler = assetHandler as? RefreshableAssetHandler else { return }
        
        self.currentPlayer.startPosition = self.currentPlayer.currentPosition
        refreshableHandler.refreshAsset(mediaSource: preferredMediaSource)
    }
    
    func addAssetRefreshObservers() {
        self.addReachabilityObserver()
        self.addAppStateChangeObserver()
        self.shouldRefreshAsset()
    }
    
    func removeAssetRefreshObservers() {
        self.removeReachabilityObserver()
        self.removeAppStateChangeObserver()
    }
    
    // Reachability Handling
    private func addReachabilityObserver() -> Void {
        guard let reachability = self.reachability else { return }
        reachability.startNotifier()
        
        reachability.onUnreachable = { reachability in
            PKLog.warning("network unreachable")
        }
        reachability.onReachable = { [weak self] reachability in
            guard let self = self else { return }
            self.handleRefreshAsset()
        }
    }
    
    private func removeReachabilityObserver() -> Void {
        self.reachability?.stopNotifier()
    }
    
    // Application States Handling
    private func addAppStateChangeObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(AVPlayerWrapper.applicationDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }
    
    private func removeAppStateChangeObserver() {
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.didBecomeActiveNotification,
                                                  object: nil)
    }
    
    @objc private func applicationDidBecomeActive() {
        self.handleRefreshAsset()
    }
    
    private func handleRefreshAsset() {
        if self.shouldRefresh {
            self.shouldRefresh = false
            self.refreshAsset()
        }
    }
}
