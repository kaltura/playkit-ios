

import Foundation
import CoreMedia
import AVFoundation

/// `AdsPlayerEngineWrapperState` represents `AdsPlayerEngineWrapper` state machine states.
enum AdsDAIPlayerEngineWrapperState: Int, StateProtocol {
    /// Initial state.
    case start = 0
    /// When prepare was requested for the first time and it is stalled until the stream URL has been received or in case of faliure.
    case waitingForPrepare
    /// A moment before we call prepare until prepare() is finished (the synchronous code only, not async tasks).
    case preparing
    /// Indicates when prepare() is finished (the synchronous code only, not async tasks).
    case prepared
}

public protocol AdsDAIPlayerEngineWrapperDelegate {
    func streamStarted()
    func adPlaying(startTime: TimeInterval, duration: TimeInterval)
    func adPaused()
    func adResumed()
    func adCompleted()
    func receivedTimedMetadata(_ metadata: [String : String])
}

public class AdsDAIPlayerEngineWrapper: PlayerEngineWrapper, AdsPluginDelegate, AdsPluginDataSource {

    public override var playerEngine: PlayerEngine? {
        didSet {
            // Add timedMetadata observer
            if let avPlayerWrapper = playerEngine as? AVPlayerWrapper {
                avPlayerWrapper.currentPlayer.addObserver(self, forKeyPath: "currentItem.timedMetadata", options: NSKeyValueObservingOptions.new, context: nil)
            }
        }
    }

    public var delegate: AdsDAIPlayerEngineWrapperDelegate?
    
    fileprivate var stateMachine = BasicStateMachine(initialState: AdsDAIPlayerEngineWrapperState.start, allowTransitionToInitialState: true)
    
    /// The media config to prepare the player with.
    /// Uses @NSCopying in order to make a copy whenever set with new value.
    @NSCopying private var prepareMediaConfig: MediaConfig!
    
    // Save the mediaSource and handler to load in case of an error with the ad plugin
    private var mediaSource: PKMediaSource?
    private var handler: AssetHandler?
    
    /// Indicates if play was used, if `play()` or `resume()` was called we set this to true.
    private var playPerformed = false
    /// Indicates if it's the first time we are starting the stream
    private var isFirstPlay = true
    
    /// A semaphore to make sure prepare will not be called from 2 threads.
    private let prepareSemaphore = DispatchSemaphore(value: 1)
    
    private let maxAdRequestTimedOutRetries = 5
    private var adRequestTimedOutRetries = 0
    
    var adStartTimeObserverToken: Any?
    var adEndTimeObserverToken: Any?
    var setCuePointsObserver: Bool = false
    var pkAdDAICuePoints: PKAdDAICuePoints = PKAdDAICuePoints([]) {
        didSet {
            if pkAdDAICuePoints.cuePoints.isEmpty { return }
            if !setCuePointsObserver {
                setCuePointsObserver = true
                
                var adStartTimes: [NSValue] = []
                var adEndTimes: [NSValue] = []
                for cuepoint in pkAdDAICuePoints.cuePoints {
                    var playerTimescale: Int32 = 1
                    if let avPlayerWrapper = playerEngine as? AVPlayerWrapper {
                        playerTimescale = avPlayerWrapper.currentPlayer.currentItem?.asset.duration.timescale ?? 1
                    }
                    adStartTimes.append(NSValue(time: CMTimeMakeWithSeconds(cuepoint.startTime, preferredTimescale: playerTimescale)))
                    adEndTimes.append(NSValue(time: CMTimeMakeWithSeconds(cuepoint.endTime, preferredTimescale: playerTimescale)))
                }
                
                if let avPlayerWrapper = playerEngine as? AVPlayerWrapper {
                    adStartTimeObserverToken = avPlayerWrapper.currentPlayer.addBoundaryTimeObserver(forTimes: adStartTimes, queue: DispatchQueue.main) { [weak self] in
                        // The PreRoll is not called, taken cared of in the play func
                        guard let strongSelf = self else { return }
                        guard let player = strongSelf.playerEngine else { return }
                        let streamCurrentPosition = player.currentPosition
                        if let ad = strongSelf.adsPlugin.canPlayAd(atStreamTime: streamCurrentPosition) {
                            if ad.canPlay {
                                strongSelf.delegate?.adPlaying(startTime: streamCurrentPosition, duration: ad.duration)
                            } else {
                                let seekTime = strongSelf.adsPlugin.contentTime(forStreamTime: (ad.endTime + 1))
                                strongSelf.seek(to: seekTime)
                            }
                        }
                    }
                    
                    adEndTimeObserverToken = avPlayerWrapper.currentPlayer.addBoundaryTimeObserver(forTimes: adEndTimes, queue: DispatchQueue.main) { [weak self] in
                        // The end time of the PostRoll is not called, taken cared of in the PKIMAVideoDisplay
                        guard let strongSelf = self else { return }
                        if strongSelf.adsPlugin.isAdPlaying {
                            strongSelf.delegate?.adCompleted()
                        }
                    }
                }
            }
        }
    }
    
    // Maintains seeking status for snapback.
    private var snapbackTime: TimeInterval = 0
    private var snapbackMode: Bool = false
    
    private var adsPlugin: AdsDAIPlugin
    
    public init(adsPlugin: AdsDAIPlugin) {
        self.adsPlugin = adsPlugin
        super.init()
        
        AppStateSubject.shared.add(observer: self)
        self.adsPlugin.delegate = self
        self.adsPlugin.dataSource = self
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        switch keyPath {
        case "currentItem.timedMetadata":
            if let avPlayerEngine = object as? AVPlayerEngine {
                if let timedMetadata = avPlayerEngine.currentItem?.timedMetadata {
                    for avMetadataItem in timedMetadata {
                        
                        let value = avMetadataItem.value as? String ?? ""
                        if value.contains("google") {

                            if let key = avMetadataItem.key, let value = avMetadataItem.stringValue {
                                delegate?.receivedTimedMetadata([key.description : value])
                            }
                            
                            return
                        }
                    }
                }
            }
        default:
            break
        }
    }
    
    /************************************************************/
    // MARK: - Private
    /************************************************************/
    
    /// Prepare the player only if it wasn't prepared yet.
    private func preparePlayerIfNeeded() {
        prepareSemaphore.wait() // Use semaphore to make sure it will not be called from more than one thread by mistake.
        
        if stateMachine.getState() == .waitingForPrepare {
            stateMachine.set(state: .preparing)
            PKLog.debug("Will prepare player")
            super.prepare(self.prepareMediaConfig)
            stateMachine.set(state: .prepared)
        }
        
        prepareSemaphore.signal()
    }
    
    func playOriginalMedia() {
        if stateMachine.getState() == .waitingForPrepare {
            preparePlayerIfNeeded()
            if let mediaSource = mediaSource, let handler = handler {
                super.loadMedia(from: mediaSource, handler: handler)
            }
            if playPerformed {
                super.play()
                adsPlugin.didPlay()
            }
        }
    }
    
    /************************************************************/
    // MARK: - PlayerEngineWrapper
    /************************************************************/
    
    public override var currentPosition: TimeInterval {
        get {
            guard let streamPosition = playerEngine?.currentPosition, streamPosition > 0 else { return 0 }
            let mediaPosition = adsPlugin.contentTime(forStreamTime: streamPosition)
            return mediaPosition
        }
        set {
            self.seek(to: newValue)
        }
    }
    
    public override var duration: TimeInterval {
        guard let streamTime = playerEngine?.duration, streamTime > 0 else { return 0 }
        let mediaDuration = adsPlugin.contentTime(forStreamTime: streamTime)
        return mediaDuration
    }
    
    override public var isPlaying: Bool {
        get {
            return super.isPlaying
        }
    }
    
    public override var currentTime: TimeInterval {
        get {
            guard let streamTime = playerEngine?.currentTime, streamTime > 0 else { return 0 }
            let mediaTime = adsPlugin.contentTime(forStreamTime: streamTime)
            return mediaTime
        }
        set {
            let streamTime = adsPlugin.streamTime(forContentTime: newValue)
            playerEngine?.currentTime = streamTime
        }
    }
    
    public override func loadMedia(from mediaSource: PKMediaSource?, handler: AssetHandler) {
        reset()
        
        self.mediaSource = mediaSource
        self.handler = handler
    }
    
    override public func play() {
        playPerformed = true
        if stateMachine.getState() == .prepared {
            adsPlugin.didRequestPlay(ofType: .play)
        } else {
            super.pause()
        }
    }
    
    override public func pause() {
        playPerformed = false
        if stateMachine.getState() == .prepared {
            super.pause()
            if adsPlugin.isAdPlaying {
                delegate?.adPaused()
            }
        }
    }
    
    override public func resume() {
        playPerformed = true
        if stateMachine.getState() == .prepared {
            adsPlugin.didRequestPlay(ofType: .resume)
        } else {
            super.pause()
        }
    }
    
    override public func stop() {
        stateMachine.set(state: .start)
        super.stop()
        adsPlugin.destroyManager()
        playPerformed = false
    }
    
    public override func replay() {
        super.replay()
        adsPlugin.didRequestPlay(ofType: .play)
    }
    
    override public func seek(to time: TimeInterval) {
        let endTime = adsPlugin.streamTime(forContentTime: time)
        guard !adsPlugin.isAdPlaying else { return }
        
        if isFirstPlay && startPosition > 0 && adsPlugin.startWithPreroll && pkAdDAICuePoints.hasPreRoll {
            startPosition = 0
            snapbackMode = true
            snapbackTime = endTime
            return
        }
        
        if !isFirstPlay {
            let startTime = super.currentPosition
            if startTime < endTime {
                // Seeking forward
                if let previousCuePoint = adsPlugin.previousCuepoint(forStreamTime: endTime), previousCuePoint.played == false {
                    snapbackMode = true
                    snapbackTime = endTime < previousCuePoint.endTime ? previousCuePoint.endTime : endTime
                    
                    let duration = previousCuePoint.endTime - previousCuePoint.startTime
                    delegate?.adPlaying(startTime: previousCuePoint.startTime, duration: duration)
                    super.seek(to: previousCuePoint.startTime)
                    return
                }
            }
        }
        
        // Seeking backwards or there wasn't a previous cuepoint which wasn't played
        super.seek(to: endTime)
    }
    
    override public func destroy() {
        if let avPlayerWrapper = playerEngine as? AVPlayerWrapper {
            // Remove Ad Start Time Observer
            if let token = adStartTimeObserverToken {
                avPlayerWrapper.currentPlayer.removeTimeObserver(token)
                adStartTimeObserverToken = nil
            }
            // Remove Ad End Time Observer
            if let token = adEndTimeObserverToken {
                avPlayerWrapper.currentPlayer.removeTimeObserver(token)
                adEndTimeObserverToken = nil
            }
        }
        AppStateSubject.shared.remove(observer: self)
        adsPlugin.destroy()
        super.destroy()
    }
    
    override public func prepare(_ config: MediaConfig) {
        prepareMediaConfig = config
        stateMachine.set(state: .waitingForPrepare)
        do {
            try adsPlugin.requestAds()
        } catch {
            preparePlayerIfNeeded()
            if playPerformed {
                play()
            }
        }
    }
    
    /************************************************************/
    // MARK: - Public
    /************************************************************/
    
    public func reset() {
        stateMachine.set(state: .start)
        mediaSource = nil
        handler = nil
        playPerformed = false
        isFirstPlay = true
        adRequestTimedOutRetries = 0
        setCuePointsObserver = false
        pkAdDAICuePoints = PKAdDAICuePoints([])
        snapbackTime = 0
        snapbackMode = false
        adsPlugin.destroyManager()
    }
    
    public func loadStream(_ streamURL: URL!) {
        mediaSource?.contentUrl = streamURL
        for source in mediaConfig?.mediaEntry.sources ?? [] {
            source.contentUrl = streamURL
        }
        if let mediaSource = mediaSource, let handler = handler {
            super.loadMedia(from: mediaSource, handler: handler)
            
            preparePlayerIfNeeded()
        }
    }
    
    /************************************************************/
    // MARK: - AdsPluginDataSource
    /************************************************************/
    
    public var playAdsAfterTime: TimeInterval {
        return prepareMediaConfig?.startTime ?? 0
    }
    
    /************************************************************/
    // MARK: - AdsPluginDelegate
    /************************************************************/
    
    public func adsPlugin(_ adsPlugin: AdsPlugin, loaderFailedWith error: String) {
        // The loader can fail also when going to the background, therefore adding the retry here as well.
        if adRequestTimedOutRetries < maxAdRequestTimedOutRetries, prepareMediaConfig != nil {
            adRequestTimedOutRetries += 1
            prepare(prepareMediaConfig)
        } else {
            playOriginalMedia()
        }
    }
    
    public func adsPlugin(_ adsPlugin: AdsPlugin, managerFailedWith error: String) {
        playOriginalMedia()
    }
    
    public func adsPlugin(_ adsPlugin: AdsPlugin, didReceive event: PKEvent) {
        switch event {
        case is AdEvent.StreamLoaded:
            preparePlayerIfNeeded()
            if let startTime = prepareMediaConfig?.startTime, startTime > 0 {
                seek(to: startTime)
            }
        case is AdEvent.AdCuePointsUpdate:
            if let adDAICuePoints = event.adDAICuePoints {
                pkAdDAICuePoints = adDAICuePoints
            }
        case is AdEvent.AdBreakStarted, is AdEvent.AdLoaded:
            break
        case is AdEvent.AdBreakEnded:
            if snapbackMode {
                snapbackMode = false
                playerEngine?.seek(to: snapbackTime)
            }
        case is AdEvent.AllAdsCompleted:
            break
        case is AdEvent.AdsRequested:
            break
        case is AdEvent.RequestTimedOut:
            adsRequestTimedOut(shouldPlay: playPerformed)
        case is AdEvent.Error:
            break
        case is AdEvent.AdDidRequestContentResume:
            break
        case is AdEvent.AdDidRequestContentPause:
            // Can't perform pause because the ad is embedded therefore the ad will be paused.
            break
        default:
            break
        }
    }
    
    public func adsRequestTimedOut(shouldPlay: Bool) {
        if stateMachine.getState() == .waitingForPrepare, adRequestTimedOutRetries < maxAdRequestTimedOutRetries {
            adRequestTimedOutRetries += 1
            prepare(prepareMediaConfig)
        } else {
            playOriginalMedia()
        }
    }
    
    public func play(_ playType: PlayType) {
        preparePlayerIfNeeded()
        if playType == .play {
            if isPlaying {
                return
            }
            
            // If there is a start position set it to the real time. Do this before play().
            if startPosition > 0 {
                let streamTime = adsPlugin.streamTime(forContentTime: startPosition)
                startPosition = streamTime
            }
            
            if isFirstPlay {
                isFirstPlay = false
                delegate?.streamStarted()
            }
            
            // PreRoll is not being caught in the BoundaryTimeObserver
            if (playerEngine?.currentPosition == 0 || Float(currentPosition) >= Float(duration)) && pkAdDAICuePoints.hasPreRoll {
                if let ad = adsPlugin.canPlayAd(atStreamTime: 0) {
                    if ad.canPlay {
                        delegate?.adPlaying(startTime: 0, duration: ad.duration)
                    } else {
                        let seekTime = adsPlugin.contentTime(forStreamTime: ad.endTime)
                        seek(to: seekTime)
                    }
                }
            } else {
                if adsPlugin.isAdPlaying {
                    delegate?.adResumed()
                }
            }
            
            super.play()
            
        } else {
            super.resume()
            if adsPlugin.isAdPlaying {
                delegate?.adResumed()
            }
        }
        adsPlugin.didPlay()
    }
}

/************************************************************/
// MARK: - AppStateObservable
/************************************************************/

extension AdsDAIPlayerEngineWrapper: AppStateObservable {
    
    public var observations: Set<NotificationObservation> {
        return [
            NotificationObservation(name: UIApplication.didEnterBackgroundNotification) { [weak self] in
                guard let self = self else { return }
                // When we enter background make sure to pause if we were playing.
                if self.isPlaying {
                    self.pause()
                }
                // Notify the ads plugin we are entering to the background.
                self.adsPlugin.didEnterBackground()
            },
            NotificationObservation(name: UIApplication.willEnterForegroundNotification) { [weak self] in
                guard let self = self else { return }
                self.adsPlugin.willEnterForeground()
            }
        ]
    }
}
