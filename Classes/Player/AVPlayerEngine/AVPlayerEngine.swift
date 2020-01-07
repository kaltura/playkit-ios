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
import CoreMedia

/// An AVPlayerEngine is a controller used to manage the playback and timing of a media asset.
/// It provides the interface to control the player’s behavior such as its ability to play, pause, and seek to various points in the timeline.
public class AVPlayerEngine: AVPlayer {
    
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
    private var backgroundTimer: Timer?
    
    // MARK: Player Properties
    
    // Attempt load and test these asset keys before playing.
    let assetKeysRequiredToPlay = [
        "playable",
        "tracks",
        "hasProtectedContent",
        "duration"
    ]

    /// Keeps reference on the last timebase rate in order to post events accuratly.
    var lastTimebaseRate: Float64 = 0
    /// The last indicated bitrate observed can tell what is the last video track bitrate that was used.
    var lastIndicatedBitrate: Double = 0
    var isObserved: Bool = false
    /// Indicates if player item was changed to state: `readyToPlay` at least once.
    /// Used to post `CanPlay` event once on first `readyToPlay`.
    var isFirstReady = true
    var currentState: PlayerState = PlayerState.idle
    var tracksManager = TracksManager()
    static var observerContext = 0
    
    var internalDuration: TimeInterval = 0.0 {
        didSet {
            if oldValue != internalDuration {
                self.post(event: PlayerEvent.DurationChanged(duration: internalDuration))
            }
        }
    }
    
    var onEventBlock: ((PKEvent) -> Void)?
    
    public weak var view: PlayerView? {
        didSet {
            view?.player = self
        }
    }
    
    fileprivate var playerLayer: AVPlayerLayer? {
        return view?.playerLayer
    }

    @objc var asset: PKAsset? {
        willSet {
            assetStatusObservation?.invalidate()
        }
        didSet {
            assetStatusObservation = observe(\.asset?.status,
                                             changeHandler: { [weak self] (object, change) in
                                                guard let self = self else { return }
                                                guard let asset = self.asset else { return }
                                                PKLog.debug("The asset status changed to: \(asset.status)")
                                                if asset.status == .prepared, self.shouldStartBuffering == true {
                                                    self.initializePlayerItem(asset)
                                                }
            })
            
            guard let newAsset = asset else { return }
            self.asynchronouslyLoadURLAsset(newAsset)
        }
    }
    var assetStatusObservation: NSKeyValueObservation?
    
    /// Indicates if the startBuffering was called
    var shouldStartBuffering: Bool = false {
        didSet {
            if shouldStartBuffering == true, self.currentItem == nil, let asset = asset, asset.status == .prepared {
                initializePlayerItem(asset)
            }
        }
    }
    
    /// Holds the current time for the current item.
    /// - Attention: **For live streams** returns relative time according to the allowed stream window.
    ///
    /// In addition, keep in mind that because the duration is calcaulated from `seekableTimeRanges`
    /// in live streams there could be a chance that current time will be bigger than the duration
    /// because the current segment wasn't yet added to the seekable time ranges.
    public var currentPosition: TimeInterval {
        get {
            let position = self.currentTime() - self.rangeStart
            
            PKLog.verbose("get currentPosition: \(position)")
            var time = CMTimeGetSeconds(position)
            
            // In some cases the video will start playing with negative current time.
            // self.currentTime() returns a large negative value
            if time < 0.0 {
                time = 0
            }
            
            // Time could be NaN in some rare cases make sure we don't return NaN and return 0 otherwise.
            return time.isNaN ? 0 : time
        }
        set {
            if newValue.isNaN { return }
            let duration = self.duration
            let value = newValue > duration ? duration : (newValue < 0 ? 0 : newValue)
            let newTime = self.rangeStart + CMTimeMakeWithSeconds(value, preferredTimescale: self.rangeStart.timescale)
            PKLog.debug("set currentPosition: \(CMTimeGetSeconds(newTime))")
            super.seek(to: newTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero) { [weak self] (isSeeked: Bool) in
                guard let self = self else { return }
                if isSeeked {
                    self.post(event: PlayerEvent.Seeked())
                    PKLog.debug("seeked")
                } else {
                    PKLog.error("seek faild")
                }
            }
            self.post(event: PlayerEvent.Seeking(targetSeekPosition: CMTimeGetSeconds(newTime)))
        }
    }
    
    var startPosition: TimeInterval {
        didSet {
            PKLog.debug("set startPosition: \(startPosition)")
        }
    }
    
    var duration: TimeInterval {
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
        
        PKLog.verbose("get duration: \(result)")
        // in some rare cases duration can be nan, in that case we will return 0.
        let duration = result.isNaN ? 0.0 : result
        internalDuration = duration
        return duration
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
            var result: CMTime = CMTimeMakeWithSeconds(0, preferredTimescale: 1)
            if let currentItem = self.currentItem {
                let seekableRanges = currentItem.seekableTimeRanges
                if seekableRanges.count > 0 {
                    if let lastSeekableTimeRange = seekableRanges.last as? CMTimeRange, lastSeekableTimeRange.isValid {
                        result = lastSeekableTimeRange.start
                    } else {
                        PKLog.debug("Seekable range is invalid")
                    }
                }
            }
            return result
        }
    }
    
    public override var rate: Float {
        get {
            return super.rate
        }
        set {
            if newValue >= 0 {
                super.rate = newValue
            }
        }
    }
    
    public var playbackType: String? {
        get {
            return self.currentItem?.accessLog()?.events.last?.playbackType
        }
    }
    
    // MARK: - Player Methods
    
    override init() {
        PKLog.verbose("init AVPlayer")
        self.startPosition = 0
        super.init()
        self.onEventBlock = nil
        AppStateSubject.shared.add(observer: self)
    }
    
    deinit {
        PKLog.debug("\(String(describing: type(of: self))), was deinitialized")
        // Removes the observers only on deinit to prevent chances of being removed twice.
        self.removeObservers()
        
        // There is a crash with the release of the KVO observer on previous versions up to iOS 11.3.
        if #available(iOS 11.3, *) {
            // No need to do anything, from iOS 11.3 the bug was fixed and the KVO observer is released.
        } else if let observer = assetStatusObservation {
            removeObserver(observer, forKeyPath: "asset.status")
        }
    }
    
    public func stop() {
        PKLog.verbose("Stop player")
        self.pause()
        self.seek(to: CMTime.zero)
        self.replaceCurrentItem(with: nil)
        self.shouldStartBuffering = false
        self.post(event: PlayerEvent.Stopped())
    }
    
    public func replay() {
        PKLog.verbose("Replay item in player")
        self.pause()
        self.seek(to: CMTime.zero)
        super.play()
        self.post(event: PlayerEvent.Replay())
    }
    
    override public func pause() {
        if self.rate > 0 {
            // Playing, so pause.
            PKLog.debug("Pause player")
            super.pause()
        }
    }
    
    override public func play() {
        if self.rate == 0 {
            PKLog.debug("Play player")
            self.post(event: PlayerEvent.Play())
            super.play()
        }
    }
    
    @available(iOS 10.0, tvOS 10.0,  *)
    override public func playImmediately(atRate rate: Float) {
        if self.rate == 0 {
            PKLog.debug("Play immediately player")
            self.post(event: PlayerEvent.Play())
            
            super.playImmediately(atRate: rate)
        }
    }
    
    private func seekToLiveEdge() {
        guard let currentItem = self.currentItem else {
            PKLog.error("Current item is empty, can't seek to live edge.")
            return
        }
        
        let seekableRanges = currentItem.seekableTimeRanges
        if seekableRanges.count > 0 {
            if let lastSeekableTimeRange = seekableRanges.last as? CMTimeRange, lastSeekableTimeRange.isValid {
                var result = CMTimeRangeGetEnd(lastSeekableTimeRange)
                let liveEdgeThreshold: Double = 2.0
                result = CMTimeSubtract(result, CMTime(seconds: liveEdgeThreshold, preferredTimescale: result.timescale))
                
                // Need to compare with the same time scale - converting
                var currentTime = self.currentTime()
                let method: CMTimeRoundingMethod = result.timescale < currentTime.timescale ? .roundTowardZero : .roundAwayFromZero
                currentTime = currentTime.convertScale(result.timescale, method: method)

                if (CMTimeCompare(currentTime, result) == -1) {
                    PKLog.debug("Seeking to live edge")
                    super.seek(to: result)
                }
            } else {
                PKLog.debug("Seekable range is invalid")
            }
        }
    }
    
    func playFromLiveEdge() {
        seekToLiveEdge()
        self.play()
    }
    
    @available(iOS 10.0, tvOS 10.0, *)
    func playFromLiveEdgeImmediately(atRate rate: Float) {
        seekToLiveEdge()
        self.playImmediately(atRate: rate)
    }
    
    func destroy() {
        PKLog.verbose("Destroy player")
        self.onEventBlock = nil
        // removes app state observer
        AppStateSubject.shared.remove(observer: self)
        self.replaceCurrentItem(with: nil)
    }
    
    public func selectTrack(trackId: String) {
        guard let currentItem = self.currentItem else {
            PKLog.error("Current item is empty")
            return
        }
        
        if trackId.isEmpty == false {
            let selectedTrack = self.tracksManager.selectTrack(item: currentItem, trackId: trackId)
            if let selectedTrack = selectedTrack {
                if selectedTrack.type == .audio {
                    self.post(event: PlayerEvent.AudioTrackChanged(track: selectedTrack))
                } else {
                    self.post(event: PlayerEvent.TextTrackChanged(track: selectedTrack))
                }
            }
        } else {
            PKLog.error("TrackId is nil")
        }
    }
    
    func post(event: PKEvent) {
        PKLog.verbose("onEvent:: \(event)")
        onEventBlock?(event)
    }
    
    func postStateChange(newState: PlayerState, oldState: PlayerState) {
        PKLog.debug("stateChanged:: new:\(newState) old:\(oldState)")
        let stateChangedEvent: PKEvent = PlayerEvent.StateChanged(newState: newState, oldState: oldState)
        self.post(event: stateChangedEvent)
    }
    
    func updateTextTrackStyling(_ textTrackStyling: PKTextTrackStyling) {
        // Currently we only support these, there are more.
        let foregroundColorARGBKey: String = kCMTextMarkupAttribute_ForegroundColorARGB as String
        let backgroundColorARGBKey: String = kCMTextMarkupAttribute_BackgroundColorARGB as String
        let baseFontSizePercentageRelativeToVideoHeightKey: String = kCMTextMarkupAttribute_BaseFontSizePercentageRelativeToVideoHeight as String
        let characterEdgeStyleKey: String = kCMTextMarkupAttribute_CharacterEdgeStyle as String
        let characterBackgroundColorARGBKey: String = kCMTextMarkupAttribute_CharacterBackgroundColorARGB as String
        let fontFamilyNameKey: String = kCMTextMarkupAttribute_FontFamilyName as String
        
        var attributes: [String : Any] = [:]
        if let foregroundColor = textTrackStyling.textColor {
            attributes.updateValue([foregroundColor.alpha, foregroundColor.red, foregroundColor.green, foregroundColor.blue], forKey: foregroundColorARGBKey)
        }
        
        if let backgroundColor = textTrackStyling.backgroundColor {
            attributes.updateValue([backgroundColor.alpha, backgroundColor.red, backgroundColor.green, backgroundColor.blue], forKey: backgroundColorARGBKey)
        }
        
        if let baseFontSize = textTrackStyling.textSize {
            attributes.updateValue(baseFontSize, forKey: baseFontSizePercentageRelativeToVideoHeightKey)
        }
        
        attributes.updateValue(textTrackStyling.edgeStyle.description, forKey: characterEdgeStyleKey)
        
        if let characterBackgroundColor = textTrackStyling.edgeColor {
            attributes.updateValue([characterBackgroundColor.alpha, characterBackgroundColor.red, characterBackgroundColor.green, characterBackgroundColor.blue], forKey: characterBackgroundColorARGBKey)
        }
        
        if let fontFamily = textTrackStyling.fontFamily {
            attributes.updateValue(fontFamily, forKey: fontFamilyNameKey)
        }
        
        guard let textStyleRule = AVTextStyleRule(textMarkupAttributes: attributes) else {
            PKLog.debug("Couldn't create AVTextStyleRule.")
            return
        }
        self.currentItem?.textStyleRules = [textStyleRule]
    }
}

/************************************************************/
// MARK: - App State Handling
/************************************************************/

extension AVPlayerEngine: AppStateObservable {
 
    public var observations: Set<NotificationObservation> {
        return [
            NotificationObservation(name: UIApplication.willTerminateNotification, onObserve: { [weak self] in
                guard let self = self else { return }
                
                PKLog.debug("player: \(self)\n Will terminate, destroying...")
                self.destroy()
            }),
            NotificationObservation(name: UIApplication.didEnterBackgroundNotification, onObserve: { [weak self] in
                guard let self = self else { return }
                
                PKLog.debug("player: \(self)\n Did enter background, finishing up...")
                self.startBackgroundTask()
            }),
            NotificationObservation(name: UIApplication.willEnterForegroundNotification, onObserve: { [weak self] in
                guard let self = self else { return }
                
                PKLog.debug("player: \(self)\n Will enter foreground...")
                self.endBackgroundTask()
            })
        ]
    }
    
    func startBackgroundTask() {
        self.backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "AVPlayerEngineBackgroundTask", expirationHandler: { [weak self] in
            guard let self = self else { return }
            
            PKLog.debug("player: \(self)\n Reached the expirationHandler")
            self.endBackgroundTask()
        })

        if self.backgroundTaskIdentifier == UIBackgroundTaskIdentifier.invalid {
            PKLog.debug("backgroundTaskIdentifier is invalid, can't create backgroundTask.")
        } else {
            PKLog.debug("backgroundTaskIdentifier:\(String(describing: self.backgroundTaskIdentifier)))")
            self.backgroundTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(endBackgroundTask), userInfo: nil, repeats: false)
        }
    }

    @objc func endBackgroundTask() {
        if self.backgroundTaskIdentifier != UIBackgroundTaskIdentifier.invalid {
            PKLog.debug("player: \(self)\n Ending the background task...(backgroundTaskIdentifier:\(String(describing: backgroundTaskIdentifier)))")
            self.backgroundTimer?.invalidate()
            self.backgroundTimer = nil
            UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            self.backgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
        }
    }
}
