

import Foundation
import CoreMedia

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
}

public class AdsDAIPlayerEngineWrapper: PlayerEngineWrapper, AdsPluginDelegate, AdsPluginDataSource {

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
    
    /// When playing post roll google sends content resume when finished.
    /// In our case we need to prevent sending play/resume to the player because the content already ended.
    var shouldPreventContentResume = false
    
    var adStartTimeObserverToken: Any?
    var adEndTimeObserverToken: Any?
    var setCuePointsObserver: Bool = false
    var pkAdDAICuePoints: PKAdDAICuePoints = PKAdDAICuePoints([]) {
        didSet {
            if !self.setCuePointsObserver {
                self.setCuePointsObserver = true
                
                var adStartTimes: [NSValue] = []
                var adEndTimes: [NSValue] = []
                for cuepoint in pkAdDAICuePoints.cuePoints {
                    adStartTimes.append(NSValue(time: CMTimeMakeWithSeconds(cuepoint.startTime, 1)))
                    adEndTimes.append(NSValue(time: CMTimeMakeWithSeconds(cuepoint.endTime, 1)))
                }
                
                if let avPlayerWrapper = playerEngine as? AVPlayerWrapper {
                    adStartTimeObserverToken = avPlayerWrapper.currentPlayer.addBoundaryTimeObserver(forTimes: adStartTimes, queue: DispatchQueue.main) { [weak self] in
                        guard let strongSelf = self else { return }
                        guard let player = strongSelf.playerEngine else { return }
                        let currentPosition = player.currentPosition
                        let ad = strongSelf.adsPlugin.canPlayAd(atStreamTime: currentPosition)
                        if ad.canPlay {
                            strongSelf.delegate?.adPlaying(startTime: currentPosition, duration: ad.duration)
                        } else {
                            let seekTime = currentPosition + ad.duration
                            print("Nilit: seek over")
                            strongSelf.seek(to: seekTime)
                        }
                    }
                    
                    adEndTimeObserverToken = avPlayerWrapper.currentPlayer.addBoundaryTimeObserver(forTimes: adEndTimes, queue: DispatchQueue.main) { [weak self] in
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
    private var seekTo: TimeInterval = 0
    private var snapbackMode: Bool = false
    
    private var adsPlugin: AdsDAIPlugin
    
    public init(adsPlugin: AdsDAIPlugin) {
        self.adsPlugin = adsPlugin
        super.init()
        
        AppStateSubject.shared.add(observer: self)
        self.adsPlugin.delegate = self
        self.adsPlugin.dataSource = self
    }
    
    /************************************************************/
    // MARK: - Private
    /************************************************************/
    
    /// Prepare the player only if it wasn't prepared yet.
    private func preparePlayerIfNeeded() {
        self.prepareSemaphore.wait() // use semaphore to make sure will not be called from more than one thread by mistake.
        
        if self.stateMachine.getState() == .waitingForPrepare {
            self.stateMachine.set(state: .preparing)
            PKLog.debug("Will prepare player")
            super.prepare(self.prepareMediaConfig)
            self.stateMachine.set(state: .prepared)
        }
        
        self.prepareSemaphore.signal()
    }
    
    /************************************************************/
    // MARK: - Public
    /************************************************************/
    
    override public var isPlaying: Bool {
        get {
            return super.isPlaying
        }
    }
    
    override public func prepare(_ config: MediaConfig) {
        self.stateMachine.set(state: .start)
        self.adsPlugin.destroyManager()
//            self.isPlayEnabled = false
        self.shouldPreventContentResume = false
        
        self.stateMachine.set(state: .waitingForPrepare)
        self.prepareMediaConfig = config
        do {
            try self.adsPlugin.requestAds()
        } catch {
            self.preparePlayerIfNeeded()
            if playPerformed {
                self.play()
            }
        }
    }
    
    public func loadStream(_ streamURL: URL!) {
        self.mediaSource?.contentUrl = streamURL
        for source in self.mediaConfig?.mediaEntry.sources ?? [] {
            source.contentUrl = streamURL
        }
        if let mediaSource = self.mediaSource, let handler = self.handler {
            super.loadMedia(from: mediaSource, handler: handler)
            self.preparePlayerIfNeeded()
            if playPerformed {
                self.play()
            }
        }
    }
    
    public override func loadMedia(from mediaSource: PKMediaSource?, handler: AssetHandler) {
        self.mediaSource = mediaSource
        self.handler = handler
    }
    
    public override var duration: TimeInterval {
        guard let streamTime = self.playerEngine?.duration, streamTime > 0 else { return 0 }
        let mediaDuration = adsPlugin.contentTime(forStreamTime: streamTime)
        return mediaDuration
    }
    
    public override var currentPosition: TimeInterval {
        get {
            guard let streamPosition = self.playerEngine?.currentPosition, streamPosition > 0 else { return 0 }
            let mediaPosition = adsPlugin.contentTime(forStreamTime: streamPosition)
//            print("Nilit: \(mediaPosition)")
            return mediaPosition
        }
        set {
            let streamPosition = adsPlugin.streamTime(forContentTime: newValue)
            self.playerEngine?.currentPosition = streamPosition
        }
    }
    
    public override var currentTime: TimeInterval {
        get {
            guard let streamTime = self.playerEngine?.currentTime, streamTime > 0 else { return 0 }
            let mediaTime = adsPlugin.contentTime(forStreamTime: streamTime)
            return mediaTime
        }
        set {
            let streamTime = adsPlugin.streamTime(forContentTime: newValue)
            self.playerEngine?.currentTime = streamTime
        }
    }
    
    override public func play() {
        self.playPerformed = true
        if self.stateMachine.getState() == .prepared {
            self.adsPlugin.didRequestPlay(ofType: .play)
        } else {
            super.pause()
        }
    }
    
    override public func resume() {
        self.playPerformed = true
        if self.stateMachine.getState() == .prepared {
            self.adsPlugin.didRequestPlay(ofType: .resume)
        } else {
            super.pause()
        }
    }
    
    override public func pause() {
        self.playPerformed = false
        if self.stateMachine.getState() == .prepared {
            super.pause()
            if adsPlugin.isAdPlaying {
                delegate?.adPaused()
            }
        }
    }
    
    override public func stop() {
        self.stateMachine.set(state: .start)
        super.stop()
        self.adsPlugin.destroyManager()
        self.playPerformed = false
        self.shouldPreventContentResume = false
    }
    
    override public func seek(to time: TimeInterval) {
        let endTime = self.adsPlugin.streamTime(forContentTime: time)
        
        guard !adsPlugin.isAdPlaying else { return }
        
        let startTime = super.currentPosition
        if startTime < endTime {
            // Seeking forward
            if let previousCuePoint = adsPlugin.previousCuepoint(forStreamTime: endTime), previousCuePoint.played == false {
                self.snapbackMode = true
                self.seekTo = endTime < previousCuePoint.endTime ? previousCuePoint.endTime : endTime
                // Add 1 to the seek time to get the keyframe at the start of the ad to be our landing place.
                super.seek(to: previousCuePoint.startTime)
                let duration = previousCuePoint.endTime - previousCuePoint.startTime
                delegate?.adPlaying(startTime: previousCuePoint.startTime, duration: duration)
                return
            }
        }
        
        // Seeking backwards or there wasn't a previous cuepoint which wasn't played
        super.seek(to: endTime)
    }
    
    override public func destroy() {
        if let avPlayerWrapper = playerEngine as? AVPlayerWrapper {
            if let token = adStartTimeObserverToken {
                avPlayerWrapper.currentPlayer.removeTimeObserver(token)
                adStartTimeObserverToken = nil
            }
            if let token = adEndTimeObserverToken {
                avPlayerWrapper.currentPlayer.removeTimeObserver(token)
                adEndTimeObserverToken = nil
            }
        }
        AppStateSubject.shared.remove(observer: self)
        adsPlugin.destroy()
        super.destroy()
    }
    
    /************************************************************/
    // MARK: - AdsPluginDataSource
    /************************************************************/
    
    public func adsPluginShouldPlayAd(_ adsPlugin: AdsPlugin) -> Bool {
        guard let player = adsPlugin.player else {
            return false
        }
        return player.delegate?.playerShouldPlayAd?(player) ?? false
    }
    
    public var playAdsAfterTime: TimeInterval {
        return self.prepareMediaConfig?.startTime ?? 0
    }
    
    /************************************************************/
    // MARK: - AdsPluginDelegate
    /************************************************************/
    
    public func adsPlugin(_ adsPlugin: AdsPlugin, loaderFailedWith error: String) {
        if stateMachine.getState() == .waitingForPrepare {
            self.preparePlayerIfNeeded()
            if let mediaSource = self.mediaSource, let handler = self.handler {
                super.loadMedia(from: mediaSource, handler: handler)
            }
            if self.playPerformed {
                super.play()
                self.adsPlugin.didPlay()
            }
        }
    }
    
    public func adsPlugin(_ adsPlugin: AdsPlugin, managerFailedWith error: String) {
        if stateMachine.getState() == .waitingForPrepare {
            self.preparePlayerIfNeeded()
            if self.playPerformed {
                super.play()
                self.adsPlugin.didPlay()
            }
        }
    }
    
    public func adsPlugin(_ adsPlugin: AdsPlugin, didReceive event: PKEvent) {
        switch event {
        case is AdEvent.StreamLoaded:
            self.preparePlayerIfNeeded()
        case is AdEvent.AdCuePointsUpdate:
            if let adDAICuePoints = event.adDAICuePoints {
                self.pkAdDAICuePoints = adDAICuePoints
            }
        case is AdEvent.AdBreakStarted, is AdEvent.AdLoaded:
            if self.shouldPreventContentResume == true { return } // no need to handle twice if already true
            if event.adInfo?.positionType == .postRoll {
                self.shouldPreventContentResume = true
            }
        case is AdEvent.AdBreakEnded:
            if self.snapbackMode {
                self.snapbackMode = false
                self.playerEngine?.seek(to: self.seekTo)
            }
        case is AdEvent.AllAdsCompleted:
            self.shouldPreventContentResume = false
        case is AdEvent.AdsRequested:
            break
        case is AdEvent.RequestTimedOut:
            self.adsRequestTimedOut(shouldPlay: playPerformed)
        case is AdEvent.Error:
            print("Nilit")
        default:
//            print("Nilit: \(event) not taken care of (AdsDAIPlayerEngineWrapper:adsPlugin:)")
            break
        }
    }
    
    public func adsRequestTimedOut(shouldPlay: Bool) {
        if shouldPlay {
            self.preparePlayerIfNeeded()
            self.play()
        }
    }
    
    public func play(_ playType: PlayType) {
        self.preparePlayerIfNeeded()
        if playType == .play {
            if isFirstPlay {
                isFirstPlay = false
                delegate?.streamStarted()
            }
            
            if playerEngine?.currentPosition == 0 && pkAdDAICuePoints.hasPreRoll {
                let ad = self.adsPlugin.canPlayAd(atStreamTime: 0)
                if ad.canPlay {
                    super.play()
                    delegate?.adPlaying(startTime: 0, duration: ad.duration)
                } else {
                    let seekTime = ad.duration
                    seek(to: seekTime)
                    super.play()
                }
            } else {
                super.play()
                if adsPlugin.isAdPlaying {
                    delegate?.adResumed()
                }
            }
            
        } else {
            super.resume()
            if adsPlugin.isAdPlaying {
                delegate?.adResumed()
            }
        }
        self.adsPlugin.didPlay()
    }
}

/************************************************************/
// MARK: - AppStateObservable
/************************************************************/

extension AdsDAIPlayerEngineWrapper: AppStateObservable {
    
    public var observations: Set<NotificationObservation> {
        return [
            NotificationObservation(name: .UIApplicationDidEnterBackground) { [weak self] in
                // When we enter background make sure to pause if we were playing.
                self?.pause()
                // Notify the ads plugin we are entering to the background.
                self?.adsPlugin.didEnterBackground()
            },
            NotificationObservation(name: .UIApplicationWillEnterForeground) { [weak self] in
                self?.adsPlugin.willEnterForeground()
            }
        ]
    }
}
