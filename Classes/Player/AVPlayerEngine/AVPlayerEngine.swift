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
    
    var onEventBlock: ((PKEvent) -> Void)?
    
    public weak var view: PlayerView? {
        didSet {
            view?.player = self
        }
    }
    
    fileprivate var playerLayer: AVPlayerLayer? {
        return view?.playerLayer
    }

    var asset: PKAsset? {
        didSet {
            guard let newAsset = asset else { return }
            self.asynchronouslyLoadURLAsset(newAsset)
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
            PKLog.trace("get currentPosition: \(position)")
            let time = CMTimeGetSeconds(position)
            // time could be NaN in some rare cases make sure we don't return NaN and return 0 otherwise.
            return time.isNaN ? 0 : time
        }
        set {
            let newTime = self.rangeStart + CMTimeMakeWithSeconds(newValue, 1)
            PKLog.debug("set currentPosition: \(CMTimeGetSeconds(newTime))")
            super.seek(to: newTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero) { [weak self] (isSeeked: Bool) in
                guard let strongSelf = self else { return }
                if isSeeked {
                    strongSelf.post(event: PlayerEvent.Seeked())
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
        
        PKLog.trace("get duration: \(result)")
        // in some rare cases duration can be nan, in that case we will return 0.
        return result.isNaN ? 0.0 : result
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
    
    // MARK: Player Methods
    
    override init() {
        PKLog.info("init AVPlayer")
        self.startPosition = 0
        super.init()
        self.onEventBlock = nil
        AppStateSubject.shared.add(observer: self)
    }
    
    deinit {
        PKLog.debug("\(String(describing: type(of: self))), was deinitialized")
        // removes the observers only on deinit to prevent chances of being removed twice.
        self.removeObservers()
    }
    
    public func stop() {
        PKLog.info("stop player")
        self.pause()
        self.seek(to: kCMTimeZero)
        self.replaceCurrentItem(with: nil)
        self.post(event: PlayerEvent.Stopped())
    }
    
    override public func pause() {
        if self.rate > 0 {
            // Playing, so pause.
            PKLog.debug("pause player")
            super.pause()
        }
    }
    
    override public func play() {
        if self.rate == 0 {
            PKLog.debug("play player")
            self.post(event: PlayerEvent.Play())
            super.play()
        }
    }
    
    func destroy() {
        PKLog.info("destroy player")
        self.onEventBlock = nil
        // removes app state observer
        AppStateSubject.shared.remove(observer: self)
        self.replaceCurrentItem(with: nil)
    }
    
    public func selectTrack(trackId: String) {
        guard let currentItem = self.currentItem else { return }
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
            PKLog.error("trackId is nil")
        }
    }
    
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
// MARK: - App State Handling
/************************************************************/

extension AVPlayerEngine: AppStateObservable {
 
    public var observations: Set<NotificationObservation> {
        return [
            NotificationObservation(name: .UIApplicationWillTerminate) { [unowned self] in
                PKLog.debug("player: \(self)\n will terminate, destroying...")
                self.destroy()
            }
        ]
    }
}
