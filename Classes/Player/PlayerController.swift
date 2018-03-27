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

class PlayerController: NSObject, Player {
    
    /************************************************************/
    // MARK: - Properties
    /************************************************************/
    
    var onEventBlock: ((PKEvent) -> Void)?
    
    weak var delegate: PlayerDelegate?
    
    fileprivate var currentPlayer: PlayerEngine
    
    /// Current selected media source
    fileprivate var selectedSource: PKMediaSource?
    /// Current handler for the selected source
    fileprivate var assetHandler: AssetHandler?
    /// Current media config that was set
    private var mediaConfig: MediaConfig?
    /// A semaphore to make sure prepare calling will wait till assetToPrepare it set.
    private let prepareSemaphore = DispatchSemaphore(value: 0)
    
    let settings = PKPlayerSettings()
    
    var mediaFormat = PKMediaSource.MediaFormat.unknown
    
    /* Time Observation */
    var timeObserver: TimeObserver!
    
    public var mediaEntry: PKMediaEntry? {
        return self.mediaConfig?.mediaEntry
    }
    
    public var duration: TimeInterval {
        return self.currentPlayer.duration
    }
    
    public var currentState: PlayerState {
        return self.currentPlayer.currentState
    }
    
    public var isPlaying: Bool {
        return self.currentPlayer.isPlaying
    }
    
    public var currentTime: TimeInterval {
        get {
            if self.currentPlayer.currentPosition != TimeInterval.infinity && self.currentPlayer.currentPosition > self.duration {
                return self.duration
            }
            return self.currentPlayer.currentPosition
        }
        set {
            self.seek(to: newValue)
        }
    }
    
    public var currentAudioTrack: String? {
        return self.currentPlayer.currentAudioTrack
    }
    
    public var currentTextTrack: String? {
        return self.currentPlayer.currentTextTrack
    }
    
    public weak var view: PlayerView? {
        get { return self.currentPlayer.view }
        set { self.currentPlayer.view = newValue }
    }
    
    public var sessionId: String {
        return self.sessionUUID.uuidString + ":" + (self.mediaSessionUUID?.uuidString ?? "")
    }
    
    public var rate: Float {
        get {
            return self.currentPlayer.rate
        }
        set {
            self.currentPlayer.rate = newValue
        }
    }
    
    public var loadedTimeRanges: [PKTimeRange]? {
        return self.currentPlayer.loadedTimeRanges
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
        // Since currentPlayer is PlayerEngine! 
        // Dafault Wrapper creation for safety
        self.currentPlayer = DefaultPlayerWrapper()
        
        super.init()
        self.timeObserver = TimeObserver(timeProvider: self)
        self.currentPlayer.onEventBlock = { [weak self] event in
            PKLog.trace("postEvent:: \(event)")
            self?.onEventBlock?(event)
        }
        self.onEventBlock = nil
    }
    
    deinit {
        self.timeObserver.stopTimer()
        self.timeObserver.removePeriodicObservers()
        self.timeObserver.removeBoundaryObservers()
    }
    
    /************************************************************/
    // MARK: - Functions
    /************************************************************/
    
    func setMedia(from mediaConfig: MediaConfig) {
        self.mediaConfig = mediaConfig
        
        // create new media session uuid
        self.mediaSessionUUID = UUID()
        
        // get the preferred media source and post source selected event
        guard let (selectedSource, handler) = SourceSelector.selectSource(from: mediaConfig.mediaEntry) else { return }
        self.onEventBlock?(PlayerEvent.SourceSelected(mediaSource: selectedSource))
        self.selectedSource = selectedSource
        self.assetHandler = handler
        
        // update the media source request adapter with new media uuid if using kaltura request adapter
        var pms = selectedSource
        self.updateRequestAdapter(in: &pms)
        
        // Take saved eventBlock from DefaultPlayerWrapper
        // Must be called before `self.currentPlayer` reference is changed
        let eventBlock = self.currentPlayer.onEventBlock
        
        // Take saved view from DefaultPlayerWrapper
        // Must be called before `self.currentPlayer` reference is changed
        let playerView = self.currentPlayer.view
        
        // if create player wrapper returns yes meaning a new wrapper was created, otherwise same wrapper as last time is used.
        if self.createPlayerWrapper(mediaConfig) {
            // After Setting PlayerWrapper set saved player's params
            self.currentPlayer.onEventBlock = eventBlock
            self.currentPlayer.view = playerView
            self.currentPlayer.mediaConfig = mediaConfig
        }
        
        self.currentPlayer.loadMedia(from: self.selectedSource, handler: handler)
    }
    
    /// creates the wrapper if we haven't created it yet, otherwise uses the same instance we have.
    /// - Returns: true if a new player was created and false if wrapper already exists.
    private func createPlayerWrapper(_ mediaConfig: MediaConfig) -> Bool {
        let isCreated: Bool
        if (mediaConfig.mediaEntry.vrData != nil) {
            if type(of: self.currentPlayer) is VRPlayerEngine.Type { // do not create new if current player is already vr player
                isCreated = false
            } else {
                guard let vrPlayerWrapper = NSClassFromString("PlayKitVR.VRPlayerWrapper") as? VRPlayerEngine.Type else {
                    PKLog.error("VRPlayerWrapper does not exist")
                    fatalError("VR library is missing, make sure to add it via Podfile.")
                }
                self.currentPlayer = vrPlayerWrapper.init()
                isCreated = true
            }
        } else {
            if type(of: self.currentPlayer) is VRPlayerEngine.Type {
                self.currentPlayer.destroy()
                self.currentPlayer = AVPlayerWrapper()
                isCreated = true
            } else if self.currentPlayer is AVPlayerWrapper { // do not create new if current player is already vr player
                isCreated = false
            } else {
                self.currentPlayer = AVPlayerWrapper()
                isCreated = true
            }
        }
        
        if let currentPlayer = self.currentPlayer as? AVPlayerWrapper {
            currentPlayer.settings = self.settings
        }
        return isCreated
    }
    
    func prepare(_ mediaConfig: MediaConfig) {
        self.currentPlayer.prepare(mediaConfig)
        
        if let source = self.selectedSource {
            self.mediaFormat = source.mediaFormat
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
    
    func seek(to time: TimeInterval) {
        self.currentPlayer.currentPosition = time
    }
    
    func isLive() -> Bool {
        if let entry = self.mediaEntry {
            if entry.mediaType == MediaType.live {
                return true
            }
        }
        
        return false
    }
    
    func destroy() {
        self.timeObserver.stopTimer()
        self.timeObserver.removePeriodicObservers()
        self.timeObserver.removeBoundaryObservers()
        self.currentPlayer.destroy()
        self.removeAssetRefreshObservers()
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
    
    public func getController(type: PKController.Type) -> PKController? {
        if type is PKVRController.Type && self.currentPlayer is VRPlayerEngine {
            return PKVRController(player: self.currentPlayer)
        }
        
        return nil
    }
}

/************************************************************/
// MARK: - Private
/************************************************************/

fileprivate extension PlayerController {
    /// Updates the request adapter if one exists
    func updateRequestAdapter(in mediaSource: inout PKMediaSource) {
        // configure media sources content request adapter if request adapter exists
        if let adapter = self.settings.contentRequestAdapter {
            // update the request adapter with the updated session id
            adapter.updateRequestAdapter(with: self)
            // configure media source with the adapter
            mediaSource.contentRequestAdapter = adapter
        }
        
        if let adapter = self.settings.licenseRequestAdapter, let drmData = mediaSource.drmData {
            for p in drmData {
                p.requestAdapter = adapter
            }
        }
    }
}

/************************************************************/
// MARK: - Reachability & Application States Handling
/************************************************************/

extension PlayerController {
    
    private func shouldRefreshAsset() {
        guard let selectedSource = self.selectedSource,
            let refreshableHandler = assetHandler as? RefreshableAssetHandler else { return }
        
        refreshableHandler.shouldRefreshAsset(mediaSource: selectedSource) { [unowned self] (shouldRefresh) in
            if shouldRefresh {
                self.shouldRefresh = true
            }
        }
    }
    
    private func refreshAsset() {
        guard let selectedSource = self.selectedSource,
            let refreshableHandler = assetHandler as? RefreshableAssetHandler else { return }
        
        self.currentPlayer.startPosition = self.currentPlayer.currentPosition
        refreshableHandler.refreshAsset(mediaSource: selectedSource)
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
