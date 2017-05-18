//
//  AdsEnabledPlayerController.swift
//  AdsPluginExample
//
//  Created by Vadim Kononov on 03/11/2016.
//  Copyright © 2016 Vadim Kononov. All rights reserved.
//

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

class AdsEnabledPlayerController : PlayerDecoratorBase, AdsPluginDelegate, AdsPluginDataSource {
    
    enum PlayType {
        case play, resume
    }
    
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
    
    init(adsPlugin: AdsPlugin) {
        super.init()
        self.adsPlugin = adsPlugin
        AppStateSubject.shared.add(observer: self)
    }
        
    override var delegate: PlayerDelegate? {
        didSet {
            self.adsPlugin.delegate = self
            self.adsPlugin.dataSource = self
        }
    }

    override var isPlaying: Bool {
        get {
            if self.adsPlugin.isAdPlaying {
                return isPlayEnabled
            }
            return super.isPlaying
        }
    }

    override func prepare(_ config: MediaConfig) {
        self.stop()
        self.stateMachine.set(state: .waitingForPrepare)
        self.prepareMediaConfig = config
        self.adsPlugin.requestAds()
    }
    
    override func play() {
        self.isPlayEnabled = true
        self.adsPlugin.didRequestPlay(ofType: .play)
    }
    
    override func resume() {
        self.isPlayEnabled = true
        self.adsPlugin.didRequestPlay(ofType: .resume)
    }
    
    override func pause() {
        self.isPlayEnabled = false
        if self.adsPlugin.isAdPlaying {
            self.adsPlugin.pause()
        } else {
            super.pause()
        }
    }
    
    override func stop() {
        self.stateMachine.set(state: .start)
        super.stop()
        self.adsPlugin.destroyManager()
        self.isPlayEnabled = false
        self.shouldPreventContentResume = false
    }
    
    @available(iOS 9.0, *)
    override func createPiPController(with delegate: AVPictureInPictureControllerDelegate) -> AVPictureInPictureController? {
        self.adsPlugin.pipDelegate = delegate
        return super.createPiPController(with: self.adsPlugin)
    }
    
    override func destroy() {
        AppStateSubject.shared.remove(observer: self)
        super.destroy()
    }
    
    /************************************************************/
    // MARK: - AdsPluginDataSource
    /************************************************************/
        
    func adsPluginShouldPlayAd(_ adsPlugin: AdsPlugin) -> Bool {
        return self.delegate!.playerShouldPlayAd(self)
    }
    
    var adsPluginStartTime: TimeInterval {
        return self.prepareMediaConfig?.startTime ?? 0
    }
    
    /************************************************************/
    // MARK: - AdsPluginDelegate
    /************************************************************/
    
    func adsPlugin(_ adsPlugin: AdsPlugin, loaderFailedWith error: String) {
        if self.isPlayEnabled {
            self.preparePlayerIfNeeded()
            super.play()
            self.adsPlugin.didPlay()
        }
    }
    
    func adsPlugin(_ adsPlugin: AdsPlugin, managerFailedWith error: String) {
        self.preparePlayerIfNeeded()
        super.play()
        self.adsPlugin.didPlay()
    }
    
    func adsPlugin(_ adsPlugin: AdsPlugin, didReceive event: PKEvent) {
        switch event {
        case let e where type(of: e) == AdEvent.adDidRequestContentPause:
            super.pause()
        case let e where type(of: e) == AdEvent.adDidRequestContentResume:
            if !self.shouldPreventContentResume {
                self.preparePlayerIfNeeded()
                super.resume()
            }
        case let e where type(of: e) == AdEvent.adResumed: self.isPlayEnabled = true
        case let e where type(of: e) == AdEvent.adStarted:
            // when starting to play pre roll start preparing the player.
            if event.adInfo?.positionType == .preRoll {
                self.preparePlayerIfNeeded()
            }
        case let e where type(of: e) == AdEvent.adLoaded || type(of: e) == AdEvent.adBreakReady:
            if self.shouldPreventContentResume == true { return } // no need to handle twice if already true
            if event.adInfo?.positionType == .postRoll {
                self.shouldPreventContentResume = true
            }
        case let e where type(of: e) == AdEvent.allAdsCompleted: self.shouldPreventContentResume = false
        default: break
        }
    }
    
    func adsRequestTimedOut(shouldPlay: Bool) {
        if shouldPlay {
            self.preparePlayerIfNeeded()
            self.play()
        }
    }
    
    func play(_ playType: PlayType) {
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
    
    var observations: Set<NotificationObservation> {
        return [
            NotificationObservation(name: .UIApplicationDidEnterBackground) { [weak self] in
                // when we enter background make sure to pause if we were playing.
                self?.pause()
                // notify the ads plugin we are entering to the background.
                self?.adsPlugin.didEnterBackground()
            },
            NotificationObservation(name: .UIApplicationWillEnterForeground) { [weak self] in
                self?.adsPlugin.willEnterForeground()
            }
        ]
    }
}
