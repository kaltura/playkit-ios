// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license,
// unless a different license for a particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import Foundation
import AVFoundation
import AVKit
import CoreMedia

/// An AVPlayerEngine is a controller used to manage the playback and timing of a media asset.
/// It provides the interface to control the player’s behavior such as its ability to play, pause, and seek to various points in the timeline.
class AVPlayerEngine: AVPlayer {
    
    /************************************************************/
    // MARK: - Properties
    /************************************************************/
    
    // Attempt load and test these asset keys before playing.
    let assetKeysRequiredToPlay = [
        "playable",
        "tracks",
        "hasProtectedContent"
    ]

    /// Keeps reference on the last timebase rate in order to post events accuratly.
    var lastTimebaseRate: Float64 = 0
    var lastBitrate: Double = 0
    var isObserved: Bool = false
    /// Indicates if player item was changed to state: `readyToPlay` at least once.
    /// Used to post `CanPlay` event once on first `readyToPlay`.
    var isFirstReady = true
    var currentState: PlayerState = PlayerState.idle
    var tracksManager = TracksManager()
    var observerContext = 0
    var onEventBlock: ((PKEvent) -> Void)?

    var forwardBufferLogic: ForwardBufferLogic?
    /// the last time the forward buffer logic calculated a new buffer size
    var forwardBufferLogicObservedTime: TimeInterval = 0
    
    /************************************************************/
    // MARK: - Time Observing Properties
    /************************************************************/
    
    /// Used to track the amount of time the player has played the current time (total play time for current item).
    /// For example, if we played for 10s and seeked 5m forward and watch another 10s the playing is 20s.
    var timePlayed: TimeInterval = 0
    var lastObservedTime: TimeInterval = 0
    var periodicObserverInterval: TimeInterval = 0.5 // TODO: maybe in future allow app to select the interval and post event on messageBus
    var timeObserverToken: Any?
    let periodicTimeObserverDispatchQueue = DispatchQueue(label: "com.kaltura.playkit.player.periodic-observer-queue")
    
    /************************************************************/
    // MARK: - Asset Properties
    /************************************************************/
    
    var assetSettings: PKAssetSettings? {
        didSet {
            guard let assetSettings = self.assetSettings else { return }
        
            switch assetSettings.dataUsageSettings.forwardBufferMode {
            case .userEngagement, .duration: self.forwardBufferLogic = ForwardBufferLogic()
            case .durationCustom:
                self.forwardBufferLogic = ForwardBufferLogic(customDurationDecisionRanges: assetSettings.dataUsageSettings.durationModeCustomRanges)
            case .custom: break
            case .none: break
            }
            
            assetSettings.dataUsageSettings.delegate = self
        }
    }
    
    var asset: PKAsset? {
        didSet {
            guard let newAsset = asset else { return }
            self.asynchronouslyLoadURLAsset(newAsset)
        }
    }
    
    /************************************************************/
    // MARK: - Player Properties
    /************************************************************/
    
    weak var view: PlayerView? {
        didSet {
            view?.player = self
        }
    }
    
    fileprivate var playerLayer: AVPlayerLayer? {
        return view?.playerLayer
    }
    
    /// Holds the current time for the current item.
    /// - Attention: **For live streams** returns relative time according to the allowed stream window.
    ///
    /// In addition, keep in mind that because the duration is calcaulated from `seekableTimeRanges`
    /// in live streams there could be a chance that current time will be bigger than the duration
    /// because the current segment wasn't yet added to the seekable time ranges.
    var currentPosition: Double {
        get {
            let position = self.currentTime() - self.rangeStart
            PKLog.trace("get currentPosition: \(position)")
            return CMTimeGetSeconds(position)
        }
        set {
            let newTime = self.rangeStart + CMTimeMakeWithSeconds(newValue, 1)
            PKLog.debug("set currentPosition: \(CMTimeGetSeconds(newTime))")
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
    
    var startPosition: Double {
        didSet {
            PKLog.debug("set startPosition: \(startPosition)")
        }
    }
    
    var duration: Double {
        guard let currentItem = self.currentItem else { return 0.0 }
        
        var result = CMTimeGetSeconds(currentItem.duration)
        
        // This checks if the duration equals `kCMTimeIndefinite` which indicates this is a live stream.
        // Using the last range duration gives us the live window duration. 
        // For example a duration of 120seconds means we can seek up to 120 seconds from live playhead.
        if CMTIME_IS_INDEFINITE(currentItem.duration) {
            let seekableRanges = currentItem.seekableTimeRanges
            if seekableRanges.count > 0 {
                let range = seekableRanges.last!.timeRangeValue
                result = CMTimeGetSeconds(range.duration)
            }
        }
        
        PKLog.trace("get duration: \(result)")
        return result
    }
    
    var isPlaying: Bool {
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
    
    var currentAudioTrack: String? {
        if let currentItem = self.currentItem {
            return self.tracksManager.currentAudioTrack(item: currentItem)
        }
        return nil
    }
    
    var currentTextTrack: String? {
        if let currentItem = self.currentItem {
            return self.tracksManager.currentTextTrack(item: currentItem)
        }
        return nil
    }
  
    /// Gives the start time of the last seekable range.
    /// This helps calculate `currentTime` and `duration` for live streams.
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
    
    /************************************************************/
    // MARK: - Initialization
    /************************************************************/
    
    override init() {
        PKLog.info("init AVPlayer")
        self.startPosition = 0
        super.init()
        if #available(iOS 10.0, *) {
            self.automaticallyWaitsToMinimizeStalling = false
        }
        self.onEventBlock = nil
        AppStateSubject.shared.add(observer: self)
    }
    
    deinit {
        PKLog.debug("\(String(describing: type(of: self))), was deinitialized")
        // removes the observers only on deinit to prevent chances of being removed twice.
        self.removeObservers()
    }
    
    /************************************************************/
    // MARK: - Player Methods
    /************************************************************/
    
    func stop() {
        PKLog.info("stop player")
        self.pause()
        self.seek(to: kCMTimeZero)
        self.replaceCurrentItem(with: nil)
        self.post(event: PlayerEvent.Stopped())
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
            self.onEventBlock = nil
            // removes app state observer
            AppStateSubject.shared.remove(observer: self)
            self.replaceCurrentItem(with: nil)
        }
    }

    func selectTrack(trackId: String) {
        if trackId.isEmpty == false {
            self.tracksManager.selectTrack(item: self.currentItem!, trackId: trackId)
        } else {
            PKLog.error("trackId is nil")
        }
    }
    
    /************************************************************/
    // MARK: - Methods
    /************************************************************/
    
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
// MARK: - iOS Only
/************************************************************/

#if os(iOS)
    extension AVPlayerEngine {
        
        @available(iOS 9.0, *)
        func createPiPController(with delegate: AVPictureInPictureControllerDelegate) -> AVPictureInPictureController? {
            guard let playerLayer = self.playerLayer else { return nil }
            let pip = AVPictureInPictureController(playerLayer: playerLayer)
            pip?.delegate = delegate
            return pip
        }
    }
#endif

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
