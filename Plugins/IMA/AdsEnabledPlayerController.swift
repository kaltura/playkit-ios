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

class AdsEnabledPlayerController : PlayerDecoratorBase, AdsPluginDelegate, AdsPluginDataSource {
    
    enum PlayType {
        case play, resume
    }
    
    /// indicates if play was used, if `play()` or `resume()` was called we set this to true.
    var isPlayEnabled = false
    
    /// when playing post roll google sends content resume when finished.
    /// In our case we need to prevent sending play/resume to the player because the content already ended.
    var shouldPreventContentResume = false
    
    var adsPlugin: AdsPlugin!
    weak var messageBus: MessageBus?
    
    init(adsPlugin: AdsPlugin) {
        super.init()
        self.adsPlugin = adsPlugin
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

    // TODO:: finilize prepare
    override func prepare(_ config: MediaConfig) {
        super.prepare(config)
        
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
        self.adsPlugin.destroyManager()
        super.stop()
        self.isPlayEnabled = false
        self.shouldPreventContentResume = false
    }
    
    @available(iOS 9.0, *)
    override func createPiPController(with delegate: AVPictureInPictureControllerDelegate) -> AVPictureInPictureController? {
        self.adsPlugin.pipDelegate = delegate
        return super.createPiPController(with: self.adsPlugin)
    }
    
    /************************************************************/
    // MARK: - AdsPluginDataSource
    /************************************************************/
        
    func adsPluginShouldPlayAd(_ adsPlugin: AdsPlugin) -> Bool {
        return self.delegate!.playerShouldPlayAd(self)
    }
    
    /************************************************************/
    // MARK: - AdsPluginDelegate
    /************************************************************/
    
    func adsPlugin(_ adsPlugin: AdsPlugin, loaderFailedWith error: String) {
        if self.isPlayEnabled {
            super.play()
            self.adsPlugin.didPlay()
        }
    }
    
    func adsPlugin(_ adsPlugin: AdsPlugin, managerFailedWith error: String) {
        super.play()
        self.adsPlugin.didPlay()
    }
    
    func adsPlugin(_ adsPlugin: AdsPlugin, didReceive event: PKEvent) {
        switch event {
        case let e where type(of: e) == AdEvent.adDidRequestPause:
            super.pause()
        case let e where type(of: e) == AdEvent.adDidRequestResume:
            if !self.shouldPreventContentResume {
                super.resume()
            }
        case let e where type(of: e) == AdEvent.adResumed: self.isPlayEnabled = true
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
            self.play()
        }
    }
    
    func play(_ playType: PlayType) {
        playType == .play ? super.play() : super.resume()
        self.adsPlugin.didPlay()
    }
}
