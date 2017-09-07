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
    public var onEventBlock: ((PKEvent) -> Void)?
    
    public var currentPlayer: AVPlayerEngine
    
    /// the asset to prepare and pass to the player engine to start buffering.
    private var assetToPrepare: AVURLAsset?
    /// the current selected media source
    fileprivate var preferredMediaSource: PKMediaSource?
    /// the current handler for the selected source
    fileprivate var assetHandler: AssetHandler?
    /// the current media config that was set
    private var mediaConfig: MediaConfig?
    /// a semaphore to make sure prepare calling will wait till assetToPrepare it set.
    private let prepareSemaphore = DispatchSemaphore(value: 0)
    
    public var mediaEntry: PKMediaEntry? {
        return self.mediaConfig?.mediaEntry
    }
    
    public var duration: Double {
        return self.currentPlayer.duration
    }
    
    public var currentState: PlayerState {
        return self.currentPlayer.currentState
    }
    
    public var isPlaying: Bool {
        return self.currentPlayer.isPlaying
    }
    
    public var currentTime: TimeInterval {
        get { return self.currentPlayer.currentPosition }
        set { self.currentPlayer.currentPosition = newValue }
    }
    
    public var currentPosition: TimeInterval {
        get { return self.currentPlayer.currentPosition }
        set { self.currentPlayer.currentPosition = newValue }
    }
    
    public var startPosition: TimeInterval {
        get { return self.currentPlayer.startPosition }
        set { self.currentPlayer.startPosition = newValue }
    }
 
    public var currentAudioTrack: String? {
        return self.currentPlayer.currentAudioTrack
    }
    
    public var currentTextTrack: String? {
        return self.currentPlayer.currentTextTrack
    }
    
    open weak var view: PlayerView? {
        get {
            return self.currentPlayer.view
        }
        set {
            self.currentPlayer.view = newValue
        }
    }
    
    public var rate: Float {
        return self.currentPlayer.rate
    }
    
    public var loadedTimeRanges: [PKTimeRange]? {
        return self.currentPlayer.currentItem?.loadedTimeRanges.map { PKTimeRange(timeRange: $0.timeRangeValue) }
    }
    
    public override init() {
        self.currentPlayer = AVPlayerEngine()
        super.init()
        
        self.currentPlayer.onEventBlock = { [weak self] event in
            PKLog.trace("postEvent:: \(event)")
            self?.onEventBlock?(event)
        }
        self.onEventBlock = nil
    }
    
    // Every player that is created should own Reachability instance
    let reachability = PKReachability()
    var shouldRefresh: Bool = false
    
    /// Load media on player
    public func loadMedia(from mediaSource: PKMediaSource?, handlerType: AssetHandler.Type) {
        //todo::
        // build the asset from the selected source
        // TODO:: media sec fix no !
        self.assetHandler = AssetBuilder.build(from: mediaSource!, using: handlerType) { error, asset in
            if asset != nil {
                self.assetToPrepare = asset
            }
            // send signal when assetToPrepare is set
            self.prepareSemaphore.signal()
        }
    }
    
    public func prepare(_ MediaConfig: MediaConfig) throws {
        // set background thread to make sure main thread is not stuck while waiting
        DispatchQueue.global().async {
            // wait till assetToPrepare is set
            self.prepareSemaphore.wait()
            
            guard let assetToPrepare = self.assetToPrepare else { return }
            
            if let startTime = self.mediaConfig?.startTime {
                self.currentPlayer.startPosition = startTime
            }
            
            self.currentPlayer.asset = assetToPrepare
            
            if DRMSupport.widevineClassicHandler != nil {
                self.addAssetRefreshObservers()
            }
        }
    }
    
    public func play() {
        self.currentPlayer.play()
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
    
    public func seek(to time: TimeInterval) {
        self.currentPlayer.currentPosition = time
    }
    
    public func selectTrack(trackId: String) {
        self.currentPlayer.selectTrack(trackId: trackId)
    }
    
    public func destroy() {
        self.currentPlayer.destroy()
        self.removeAssetRefreshObservers()
    }
}

/************************************************************/
// MARK: - Reachability & Application States Handling
/************************************************************/

extension AVPlayerWrapper {
    
    private func shouldRefreshAsset() {
        guard let preferredMediaSource = self.preferredMediaSource,
            let refreshableHandler = assetHandler as? RefreshableAssetHandler else { return }
        
        refreshableHandler.shouldRefreshAsset(mediaSource: preferredMediaSource) { [unowned self] (shouldRefresh) in
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
        reachability.onReachable = { [unowned self] reachability in
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
                                               name: .UIApplicationDidBecomeActive,
                                               object: nil)
    }
    
    private func removeAppStateChangeObserver() {
        NotificationCenter.default.removeObserver(self,
                                                  name: .UIApplicationDidBecomeActive,
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