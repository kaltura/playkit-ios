

import Foundation

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

public class AdsDAIPlayerEngineWrapper: PlayerEngineWrapper, AdsPluginDelegate, AdsPluginDataSource {

    fileprivate var stateMachine = BasicStateMachine(initialState: AdsDAIPlayerEngineWrapperState.start, allowTransitionToInitialState: true)
    
    /// The media config to prepare the player with.
    /// Uses @NSCopying in order to make a copy whenever set with new value.
    @NSCopying private var prepareMediaConfig: MediaConfig!
    
    /// Indicates if play was used, if `play()` or `resume()` was called we set this to true.
    private var isPlayEnabled = false
    
    /// A semaphore to make sure prepare will not be called from 2 threads.
    private let prepareSemaphore = DispatchSemaphore(value: 1)
    
    /// When playing post roll google sends content resume when finished.
    /// In our case we need to prevent sending play/resume to the player because the content already ended.
    var shouldPreventContentResume = false
    
    private var adsPlugin: AdsPlugin
    
    public init(adsPlugin: AdsPlugin) {
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
                if isPlayEnabled {
                    self.play()
                }
            }
    }
    
    override public func play() {
        self.isPlayEnabled = true
        if self.stateMachine.getState() == .prepared {
            self.adsPlugin.didRequestPlay(ofType: .play)
        } else {
            super.pause()
        }
    }
    
    override public func resume() {
        self.isPlayEnabled = true
        if self.stateMachine.getState() == .prepared {
            self.adsPlugin.didRequestPlay(ofType: .resume)
        } else {
            super.pause()
        }
    }
    
    override public func pause() {
        self.isPlayEnabled = false
        if self.stateMachine.getState() == .prepared {
            super.pause()
        }
    }
    
    override public func stop() {
        self.stateMachine.set(state: .start)
        super.stop()
        self.adsPlugin.destroyManager()
        self.isPlayEnabled = false
        self.shouldPreventContentResume = false
    }
    
    override public func seek(to time: TimeInterval) {
        super.seek(to: time)
    }
    
    override public func destroy() {
        AppStateSubject.shared.remove(observer: self)
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
        print("Nilit: AdsDAIPlayerEngineWrapper adsPlugin loaderFailedWith: \(error)")
        if self.isPlayEnabled {
            self.preparePlayerIfNeeded()
            super.play()
            self.adsPlugin.didPlay()
        }
    }
    
    public func adsPlugin(_ adsPlugin: AdsPlugin, managerFailedWith error: String) {
        print("Nilit: AdsDAIPlayerEngineWrapper adsPlugin managerFailedWith: \(error)")
        self.preparePlayerIfNeeded()
        super.play()
        self.adsPlugin.didPlay()
    }
    
    public func adsPlugin(_ adsPlugin: AdsPlugin, didReceive event: PKEvent) {
        print("Nilit: AdsDAIPlayerEngineWrapper adsPlugin didReceive: \(event)")
        switch event {
        case is AdEvent.StreamLoaded:
            self.preparePlayerIfNeeded()
        case is AdEvent.AdDidRequestContentPause:
            break
        case is AdEvent.AdDidRequestContentResume:
            break
        case is AdEvent.AdPaused:
//            self.isPlayEnabled = false
            break
        case is AdEvent.AdResumed:
//            self.isPlayEnabled = true
            break
        case is AdEvent.AdStarted:
            break
        case is AdEvent.AdBreakStarted, is AdEvent.AdLoaded:
            if self.shouldPreventContentResume == true { return } // no need to handle twice if already true
            if event.adInfo?.positionType == .postRoll {
                self.shouldPreventContentResume = true
            }
        case is AdEvent.AllAdsCompleted:
            self.shouldPreventContentResume = false
        case is AdEvent.AdsRequested:
            break
        case is AdEvent.RequestTimedOut:
            self.adsRequestTimedOut(shouldPlay: isPlayEnabled)
        case is AdEvent.AdDidProgressToTime:
            break
        default:
            print("Nilit: \(event) not taken care of (AdsDAIPlayerEngineWrapper:adsPlugin:)")
            break
        }
    }
    
    public func adsRequestTimedOut(shouldPlay: Bool) {
        print("Nilit: AdsDAIPlayerEngineWrapper adsRequestTimedOut shouldPlay: \(shouldPlay)")
        if shouldPlay {
            self.preparePlayerIfNeeded()
            self.play()
        }
    }
    
    public func play(_ playType: PlayType) {
        print("Nilit: AdsDAIPlayerEngineWrapper play playType: \(playType.description)")
        self.preparePlayerIfNeeded()
        playType == .play ? super.play() : super.resume()
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
