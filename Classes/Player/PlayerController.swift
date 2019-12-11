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
    
    fileprivate var currentPlayer: PlayerEngine = DefaultPlayerWrapper() {
        // Initialize the currentPlayer to DefaultPlayerWrapper, which does nothing except printing warnings.
        didSet {
            // When set to a real player, enable the observer. 
            timeObserver.enabled = !(currentPlayer is DefaultPlayerWrapper)
        }
    }
    
    var playerEngineWrapper: PlayerEngineWrapper?
    
    /// Current selected media source
    fileprivate var selectedSource: PKMediaSource?
    /// Current handler for the selected source
    fileprivate var assetHandler: AssetHandler?
    /// Current media config that was set
    private var mediaConfig: MediaConfig?
    /// A semaphore to make sure prepare calling will wait till assetToPrepare it set.
    private let prepareSemaphore = DispatchSemaphore(value: 0)
    
    let sessionUUID = UUID()
    var mediaSessionUUID: UUID?
    
    // Every player that is created should own Reachability instance
    let reachability = PKReachability()
    var shouldRefresh: Bool = false
    
    /* Time Observation */
    lazy var timeObserver = TimeObserver(timeProvider: self)
    var playheadObserverUUID: UUID?
    
    /************************************************************/
    // MARK: - Initialization
    /************************************************************/
    
    public override init() {
        super.init()
        
        self.currentPlayer.onEventBlock = { [weak self] event in
            guard let self = self else { return }
            PKLog.verbose("postEvent:: \(event)")
            self.onEventBlock?(event)
        }
        
        self.playheadObserverUUID = self.timeObserver.addPeriodicObserver(interval: 0.1, observeOn: DispatchQueue.global()) { [weak self] (time) in
            guard let self = self else { return }
            self.onEventBlock?(PlayerEvent.PlayheadUpdate(currentTime: time))
        }
        
        self.onEventBlock = nil
    }
    
    deinit {
        if let uuid = self.playheadObserverUUID {
            self.timeObserver.removePeriodicObserver(uuid)
        }
        
        self.timeObserver.stopTimer()
        self.timeObserver.removePeriodicObservers()
        self.timeObserver.removeBoundaryObservers()
    }
    
    // ***************************** //
    // MARK: - Player
    // ***************************** //
    
    public var mediaEntry: PKMediaEntry? {
        return self.mediaConfig?.mediaEntry
    }
    
    let settings = PKPlayerSettings()
    
    var mediaFormat = PKMediaSource.MediaFormat.unknown
    
    public var sessionId: String {
        return self.sessionUUID.uuidString + ":" + (self.mediaSessionUUID?.uuidString ?? "")
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
    
    func isLive() -> Bool {
        let avPlayerItemAccessLogEventPlaybackTypeLive = "LIVE"
        if let playbackType = currentPlayer.playbackType, playbackType == avPlayerItemAccessLogEventPlaybackTypeLive {
            return true
        }
        
        if let entry = self.mediaEntry {
            if entry.mediaType == MediaType.live || entry.mediaType == MediaType.dvrLive {
                return true
            }
        }
        
        return false
    }
    
    public func getController(type: PKController.Type) -> PKController? {
        if type is PKVRController.Type && self.currentPlayer is VRPlayerEngine {
            return PKVRController(player: self.currentPlayer)
        }
        
        return nil
    }
    
    public func updatePluginConfig(pluginName: String, config: Any) {
        //Assert.shouldNeverHappen();
    }
    
    func updateTextTrackStyling() {
        self.currentPlayer.updateTextTrackStyling(self.settings.textTrackStyling)
    }
    
    // ***************************** //
    // MARK: - BasicPlayer
    // ***************************** //
    
    public var duration: TimeInterval {
        return self.currentPlayer.duration
    }
    
    public var currentState: PlayerState {
        return self.currentPlayer.currentState
    }
    
    public var isPlaying: Bool {
        return self.currentPlayer.isPlaying
    }
    
    public weak var view: PlayerView? {
        get { return self.currentPlayer.view }
        set { self.currentPlayer.view = newValue }
    }
    
    public var currentTime: TimeInterval {
        get {
            let position = self.currentPlayer.currentPosition
            let duration = self.duration
            if position != TimeInterval.infinity && position > duration {
                return duration
            }
            return position
        }
        set {
            self.seek(to: newValue)
        }
    }
    
    public var currentProgramTime: Date? {
        return self.currentPlayer.currentProgramTime
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
        return self.currentPlayer.loadedTimeRanges
    }
    
    func play() {
        if self.mediaEntry?.mediaType == .live {
            self.currentPlayer.playFromLiveEdge()
        } else {
            self.currentPlayer.play()
        }
    }
    
    func pause() {
        self.currentPlayer.pause()
    }
    
    func resume() {
        if self.mediaEntry?.mediaType == .live {
            self.currentPlayer.playFromLiveEdge()
        } else {
            self.currentPlayer.resume()
        }
    }
    
    func stop() {
        self.currentPlayer.stop()
    }
    
    func replay() {
        self.currentPlayer.replay()
    }
    
    func seek(to time: TimeInterval) {
        self.currentPlayer.currentPosition = time
    }
    
    public func selectTrack(trackId: String) {
        self.currentPlayer.selectTrack(trackId: trackId)
    }
    
    func destroy() {
        self.timeObserver.stopTimer()
        self.timeObserver.removePeriodicObservers()
        self.timeObserver.removeBoundaryObservers()
        self.currentPlayer.stop()
        self.currentPlayer.destroy()
        self.removeAssetRefreshObservers()
    }
    
    func prepare(_ mediaConfig: MediaConfig) {
        self.currentPlayer.prepare(mediaConfig)
        
        if let source = self.selectedSource {
            self.mediaFormat = source.mediaFormat
        }
    }
    
    func startBuffering() {
        currentPlayer.startBuffering()
    }
    
    // ****************************************** //
    // MARK: - Private Functions
    // ****************************************** //
    
    /// Creates the wrapper if we haven't created it yet, otherwise uses the same instance we have.
    /// - Returns: true if a new player was created and false if wrapper already exists.
    private func createPlayerWrapper(_ mediaConfig: MediaConfig) -> Bool {
        let isCreated: Bool
        if (mediaConfig.mediaEntry.vrData != nil) {
            if type(of: self.currentPlayer) is VRPlayerEngine.Type { // do not create new if current player is already vr player
                isCreated = false
            } else {
                if let vrPlayerWrapper = NSClassFromString("PlayKitVR.VRPlayerWrapper") as? VRPlayerEngine.Type {
                    self.currentPlayer = vrPlayerWrapper.init()
                    isCreated = true
                } else {
                    PKLog.error("VRPlayerWrapper does not exist, VR library is missing, make sure to add it via Podfile.")
                    // Create AVPlayer
                    if self.currentPlayer is AVPlayerWrapper { // do not create new if current player is already vr player
                        isCreated = false
                    } else {
                        self.currentPlayer = AVPlayerWrapper()
                        isCreated = true
                    }
                }
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
        
        if let playerEW = playerEngineWrapper {
            playerEW.playerEngine = currentPlayer
            currentPlayer = playerEW
        }
        
        return isCreated
    }
    
    // ****************************************** //
    // MARK: - Public Functions
    // ****************************************** //
    
    func setMedia(from mediaConfig: MediaConfig) {
        self.mediaConfig = mediaConfig
        
        // create new media session uuid
        self.mediaSessionUUID = UUID()
        
        // get the preferred media source and post source selected event
        guard let (selectedSource, handler) = SourceSelector.selectSource(from: mediaConfig.mediaEntry) else { return }
        self.onEventBlock?(PlayerEvent.SourceSelected(mediaSource: selectedSource))
        self.selectedSource = selectedSource
        self.assetHandler = handler
        
        // Update the selected source if there are external subtitles.
        selectedSource.externalSubtitle = mediaConfig.mediaEntry.externalSubtitles
        
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
        
        // Maybe update licenseRequestAdapter and fpsLicenseRequestDelegate in params
        let drmAdapter = self.settings.licenseRequestAdapter
        let licenseProvider = self.settings.fairPlayLicenseProvider
        
        if let drmData = mediaSource.drmData {
            for d in drmData {
                d.requestAdapter = drmAdapter
                
                if let fps = d as? FairPlayDRMParams {
                    fps.licenseProvider = licenseProvider
                }
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
        
        refreshableHandler.shouldRefreshAsset(mediaSource: selectedSource) { [weak self] (shouldRefresh) in
            guard let self = self else { return }
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
        reachability.onReachable = { [weak self] reachability in
            guard let self = self else { return }
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
        self.shouldRefresh = false
        self.refreshAsset()
    }
}
