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
import UIKit
import AVFoundation
import AVKit

/// `AdsPlayerState` represents `AdsEnabledPlayerController` state machine states.
enum AdsPlayerState: Int, StateProtocol {
    /// initial state.
    case start = 0
    /// when prepare was requested for the first time and it is stalled until ad started (preroll) / faliure or content resume
    case waitingForPrepare
    /// a moment before we called prepare until prepare() was finished (the sychornos code only not async tasks)
    case preparing
    /// Indicates when prepare() was finished (the sychornos code only not async tasks)
    case prepared
}

public class AdsEnabledPlayerController : PlayerDecoratorBase, AdsPluginDelegate, AdsPluginDataSource {
    
    /// The ads player state machine.
    private var stateMachine = BasicStateMachine(initialState: AdsPlayerState.start, allowTransitionToInitialState: true)
    
    /// The media config to prepare the player with.
    /// Uses @NSCopying in order to make a copy whenever set with new value.
    @NSCopying private var prepareMediaConfig: MediaConfig!
    
    /// indicates if play was used, if `play()` or `resume()` was called we set this to true.
    private var isPlayEnabled = false
    
    /// a semaphore to make sure prepare calling will not be reached from 2 threads by mistake.
    private let prepareSemaphore = DispatchSemaphore(value: 1)
    
    /// when playing post roll google sends content resume when finished.
    /// In our case we need to prevent sending play/resume to the player because the content already ended.
    var shouldPreventContentResume = false
    
    var adsPlugin: AdsPlugin!
    weak var messageBus: MessageBus?
    
    public init(adsPlugin: AdsPlugin) {
        super.init()
        self.adsPlugin = adsPlugin
        AppStateSubject.shared.add(observer: self)
        self.adsPlugin.delegate = self
        self.adsPlugin.dataSource = self
    }
    
    override public var isPlaying: Bool {
        get {
            if self.adsPlugin.isAdPlaying {
                return isPlayEnabled
            }
            return super.isPlaying
        }
    }
    
    override public func prepare(_ config: MediaConfig) {
        self.stateMachine.set(state: .start)
        self.adsPlugin.destroyManager()
        self.isPlayEnabled = false
        self.shouldPreventContentResume = false
        
        self.stateMachine.set(state: .waitingForPrepare)
        self.prepareMediaConfig = config
        do {
            try self.adsPlugin.requestAds()
        } catch {
            self.preparePlayerIfNeeded()
        }
    }
    
    override public func play() {
        self.isPlayEnabled = true
        self.adsPlugin.didRequestPlay(ofType: .play)
    }
    
    override public func resume() {
        self.isPlayEnabled = true
        self.adsPlugin.didRequestPlay(ofType: .resume)
    }
    
    override public func pause() {
        self.isPlayEnabled = false
        if self.adsPlugin.isAdPlaying {
            self.adsPlugin.pause()
        } else {
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
    
    override public func destroy() {
        AppStateSubject.shared.remove(observer: self)
        super.destroy()
    }
    
    /************************************************************/
    // MARK: - AdsPluginDataSource
    /************************************************************/
    
    public var playAdsAfterTime: TimeInterval {
        return self.prepareMediaConfig?.startTime ?? 0
    }
    
    /************************************************************/
    // MARK: - AdsPluginDelegate
    /************************************************************/
    
    public func adsPlugin(_ adsPlugin: AdsPlugin, loaderFailedWith error: String) {
        if self.isPlayEnabled {
            self.preparePlayerIfNeeded()
            super.play()
            self.adsPlugin.didPlay()
        }
    }
    
    public func adsPlugin(_ adsPlugin: AdsPlugin, managerFailedWith error: String) {
        self.preparePlayerIfNeeded()
        super.play()
        self.adsPlugin.didPlay()
    }
    
    public func adsPlugin(_ adsPlugin: AdsPlugin, didReceive event: PKEvent) {
        switch event {
        case is AdEvent.AdDidRequestContentPause:
            super.pause()
        case is AdEvent.AdDidRequestContentResume:
            if !self.shouldPreventContentResume {
                self.preparePlayerIfNeeded()
                super.resume()
            }
        case is AdEvent.AdPaused:
            self.isPlayEnabled = false
        case is AdEvent.AdResumed:
            self.isPlayEnabled = true
        case is AdEvent.AdStarted:
            // when starting to play pre roll start preparing the player.
            if event.adInfo?.positionType == .preRoll {
                self.preparePlayerIfNeeded()
            }
        case is AdEvent.AdBreakReady, is AdEvent.AdLoaded:
            if self.shouldPreventContentResume == true { return } // no need to handle twice if already true
            if event.adInfo?.positionType == .postRoll {
                self.shouldPreventContentResume = true
            }
        case is AdEvent.AllAdsCompleted:
            self.shouldPreventContentResume = false
        default:
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
        playType == .play ? super.play() : super.resume()
        self.adsPlugin.didPlay()
    }
    
    /************************************************************/
    // MARK: - Private
    /************************************************************/
    
    /// prepare the player only if wasn't prepared yet.
    private func preparePlayerIfNeeded() {
        self.prepareSemaphore.wait() // use semaphore to make sure will not be called from more than one thread by mistake.
        
        if self.stateMachine.getState() == .waitingForPrepare {
            self.stateMachine.set(state: .preparing)
            PKLog.debug("will prepare player")
            super.prepare(self.prepareMediaConfig)
            self.stateMachine.set(state: .prepared)
        }
        
        self.prepareSemaphore.signal()
    }
}

/************************************************************/
// MARK: - AppStateObservable
/************************************************************/

extension AdsEnabledPlayerController: AppStateObservable {
    
    public var observations: Set<NotificationObservation> {
        return [
            NotificationObservation(name: UIApplication.didEnterBackgroundNotification) { [weak self] in
                guard let self = self else { return }
                // when we enter background make sure to pause if we were playing.
                self.pause()
                // notify the ads plugin we are entering to the background.
                self.adsPlugin.didEnterBackground()
            },
            NotificationObservation(name: UIApplication.willEnterForegroundNotification) { [weak self] in
                guard let self = self else { return }
                self.adsPlugin.willEnterForeground()
            }
        ]
    }
}
