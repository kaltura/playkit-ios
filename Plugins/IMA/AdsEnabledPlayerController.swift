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
    
    var isAdPlayback = false
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
            self.adsPlugin.requestAds()
        }
    }

    override var isPlaying: Bool {
        get {
            if isAdPlayback {
                return isPlayEnabled
            }
            return super.isPlaying
        }
    }

    override func play() {
        self.isPlayEnabled = true
        if !self.adsPlugin.start(showLoadingView: true) {
            super.play()
        }
    }
    
    override func pause() {
        self.isPlayEnabled = false
        if isAdPlayback {
            self.adsPlugin.pause()
        } else {
            super.pause()
        }
    }
    
    override func resume() {
        self.isPlayEnabled = true
        if isAdPlayback {
            self.adsPlugin.resume()
        } else {
            super.resume()
        }
    }
    
    @available(iOS 9.0, *)
    override func createPiPController(with delegate: AVPictureInPictureControllerDelegate) -> AVPictureInPictureController? {
        self.adsPlugin.pipDelegate = delegate
        return super.createPiPController(with: self.adsPlugin)
    }
    
        
    func adsPluginShouldPlayAd(_ adsPlugin: AdsPlugin) -> Bool {
        return self.delegate!.playerShouldPlayAd(self)
    }
    
    func adsPlugin(_ adsPlugin: AdsPlugin, loaderFailedWith error: String) {
        if self.isPlayEnabled {
            super.play()
        }
    }
    
    func adsPlugin(_ adsPlugin: AdsPlugin, managerFailedWith error: String) {
        super.play()
        self.isAdPlayback = false
    }
    
    func adsPlugin(_ adsPlugin: AdsPlugin, didReceive event: PKEvent) {
        if event is AdEvent.AdDidRequestPause {
            self.isAdPlayback = true
            super.pause()
        } else if event is AdEvent.AdDidRequestResume {
            self.isAdPlayback = false
            if !self.shouldPreventContentResume {
                super.resume()
            }
        } else if event is AdEvent.AdResumed {
            self.isPlayEnabled = true
        } else if event is AdEvent.AdInformation {
            if event.adInfo?.positionType == .postRoll {
                self.shouldPreventContentResume = true
            }
        } else if event is AdEvent.AllAdsCompleted {
            self.shouldPreventContentResume = false
        }
    }
}
