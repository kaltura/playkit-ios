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

class PlayerController: NSObject, Player, PlayerSettings {
    
    /************************************************************/
    // MARK: - Properties
    /************************************************************/
    
    var onEventBlock: ((PKEvent) -> Void)?
    
    weak var delegate: PlayerDelegate?
    
    fileprivate var currentPlayer: AVPlayerEngine
    
    /// the asset to prepare and pass to the player engine to start buffering.
    private var assetToPrepare: AVURLAsset?
    /// the current selected media source
    fileprivate var preferredMediaSource: MediaSource?
    /// the current handler for the selected source
    fileprivate var assetHandler: AssetHandler?
    /// the current media config that was set
    private var mediaConfig: MediaConfig?
    /// a semaphore to make sure prepare calling will wait till assetToPrepare it set.
    private let prepareSemaphore = DispatchSemaphore(value: 0)
    
    /* Time Observation */
    private var timeObservers = [Any]()
    private var boundaryObservers = [Any]()
    
    var contentRequestAdapter: PKRequestParamsAdapter?
    
    var settings: PlayerSettings {
        return self
    }
    
    public var mediaEntry: MediaEntry? {
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
    
    public var currentAudioTrack: String? {
        return self.currentPlayer.currentAudioTrack
    }
    
    public var currentTextTrack: String? {
        return self.currentPlayer.currentTextTrack
    }
    
    public weak var view: PlayerView? {
        get {
            return self.currentPlayer.view
        }
        set {
            self.currentPlayer.view = newValue
        }
    }
    
    public var sessionId: String {
        return self.sessionUUID.uuidString + ":" + (self.mediaSessionUUID?.uuidString ?? "")
    }
    
    public var rate: Float {
        return self.currentPlayer.rate
    }
    
    public var loadedTimeRanges: [PKTimeRange]? {
        return self.currentPlayer.currentItem?.loadedTimeRanges.map { PKTimeRange(timeRange: $0.timeRangeValue) }
    }
    
    let sessionUUID = UUID()
    var mediaSessionUUID: UUID?
    
    // Every player that is created should own Reachability instance
    let reachability = PKReachability()
    var shouldRefresh: Bool = false
    
    /************************************************************/
    // MARK: - Initialization
    /************************************************************/
    
    public override init() {
        self.currentPlayer = AVPlayerEngine()
        super.init()
        
        self.currentPlayer.onEventBlock = { [weak self] event in
            PKLog.trace("postEvent:: \(event)")
            self?.onEventBlock?(event)
        }
        self.onEventBlock = nil
    }
    
    deinit {
        self.removeTimeObservers()
        self.removeTimeBoundaryObservers()
    }
    
    /************************************************************/
    // MARK: - Functions
    /************************************************************/
    
    func setMedia(from mediaConfig: MediaConfig) {
        self.mediaConfig = mediaConfig
        // create new media session uuid
        self.mediaSessionUUID = UUID()
        
        // get the preferred media source and post source selected event
        guard let (preferredMediaSource, handlerType) = AssetBuilder.getPreferredMediaSource(from: mediaConfig.mediaEntry) else { return }
        self.onEventBlock?(PlayerEvent.SourceSelected(mediaSource: preferredMediaSource))
        self.preferredMediaSource = preferredMediaSource
        
        // update the media source request adapter with new media uuid if using request adapter
        var pms = preferredMediaSource
        self.updateRequestAdapter(in: &pms)
        
        // build the asset from the selected source
        self.assetHandler = AssetBuilder.build(from: preferredMediaSource, using: handlerType) { error, asset in
            if let assetToPrepare = asset {
                self.assetToPrepare = assetToPrepare
            }
            // send signal when assetToPrepare is set
            self.prepareSemaphore.signal()
        }
    }
    
    func prepare(_ config: MediaConfig) {
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
    
    func play() {
        self.currentPlayer.play()
    }
    
    func pause() {
        self.currentPlayer.pause()
    }
    
    func resume() {
        self.currentPlayer.play()
    }
    
    func stop() {
        self.currentPlayer.stop()
    }
    
    func seek(to time: CMTime) {
        self.currentPlayer.currentPosition = CMTimeGetSeconds(time)
    }
    
    func destroy() {
        self.currentPlayer.destroy()
        self.removeAssetRefreshObservers()
        self.removeTimeObservers()
        self.removeTimeBoundaryObservers()
    }
    
    func addObserver(_ observer: AnyObject, event: PKEvent.Type, block: @escaping (PKEvent) -> Void) {
        //Assert.shouldNeverHappen();
    }
    
    func addObserver(_ observer: AnyObject, events: [PKEvent.Type], block: @escaping (PKEvent) -> Void) {
        //Assert.shouldNeverHappen();
    }
    
    func removeObserver(_ observer: AnyObject, event: PKEvent.Type) {
        //Assert.shouldNeverHappen();
    }
    
    func removeObserver(_ observer: AnyObject, events: [PKEvent.Type]) {
        //Assert.shouldNeverHappen();
    }
    
    public func selectTrack(trackId: String) {
        self.currentPlayer.selectTrack(trackId: trackId)
    }
    
    public func updatePluginConfig(pluginName: String, config: Any) {
        //Assert.shouldNeverHappen();
    }
    
    public func addTimeObserver(interval: TimeInterval, observeOn queue: DispatchQueue? = nil, using block: @escaping (CMTime) -> Void) {
        let timeInterval = CMTime(seconds: interval, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        self.timeObservers.append(self.currentPlayer.addPeriodicTimeObserver(forInterval: timeInterval, queue: queue ?? DispatchQueue.main, using: block))
    }
    
    public func addTimeBoundaryObserver(boundaries: [PKTimeBoundary], observeOn queue: DispatchQueue? = nil, using block: @escaping () -> Void) {
        guard let duration = self.currentPlayer.asset?.duration else { return } // must have duration to add boundary observer
        var times = [NSValue]()
        for boundary in boundaries {
            times.append(boundary.boundaryCMTimeValue(usingTime: duration))
        }
        self.boundaryObservers.append(self.currentPlayer.addBoundaryTimeObserver(forTimes: times, queue: DispatchQueue.main, using: block))
    }
    
    public func removeTimeObservers() {
        for timeObserver in self.timeObservers {
            self.currentPlayer.removeTimeObserver(timeObserver)
        }
        self.timeObservers.removeAll()
    }
    
    public func removeTimeBoundaryObservers() {
        for timeObserver in self.boundaryObservers {
            self.currentPlayer.removeTimeObserver(timeObserver)
        }
        self.boundaryObservers.removeAll()
    }
}

/************************************************************/
// MARK: - iOS Only
/************************************************************/

#if os(iOS)
    extension PlayerController {
        
        @available(iOS 9.0, *)
        func createPiPController(with delegate: AVPictureInPictureControllerDelegate) -> AVPictureInPictureController? {
            return self.currentPlayer.createPiPController(with: delegate)
        }
    }
#endif

/************************************************************/
// MARK: - Private
/************************************************************/

extension PlayerController {
    
    /// Updates the request adapter if one exists
    fileprivate func updateRequestAdapter(in mediaSource: inout MediaSource) {
        // configure media sources content request adapter if request adapter exists
        if let adapter = self.contentRequestAdapter {
            // update the request adapter with the updated session id
            adapter.updateRequestAdapter(with: self)
            // configure media source with the adapter
            mediaSource.contentRequestAdapter = adapter
        }
    }
}

/************************************************************/
// MARK: - Reachability & Application States Handling
/************************************************************/

extension PlayerController {
    
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
            if self.shouldRefresh {
                self.handleRefreshAsset()
            }
        }
    }
    
    private func removeReachabilityObserver() -> Void {
        self.reachability?.stopNotifier()
    }
    
    // Application States Handling
    private func addAppStateChangeObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(PlayerController.applicationDidBecomeActive),
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
        self.shouldRefresh = false
        self.refreshAsset()
    }
}
