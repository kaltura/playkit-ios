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
    var isPlaying = false
    var adsPlugin: AdsPlugin!
    weak var messageBus: MessageBus?
    
    init(adsPlugin: AdsPlugin) {
        super.init()
        self.adsPlugin = adsPlugin
    }
    
    override func setPlayer(_ player: Player!) {
        super.setPlayer(player)
        
        messageBus?.addObserver(self, events: [PlayerEvents.ended.self], block: { (data: Any) -> Void in
            self.adsPlugin.contentComplete()
        })
    }
    
    override var delegate: PlayerDelegate? {
        didSet {
            self.adsPlugin.delegate = self
            self.adsPlugin.dataSource = self
            self.adsPlugin.requestAds()
        }
    }
    
    override func play() {
        self.isPlaying = true
        if !self.adsPlugin.start(showLoadingView: true) {
            super.play()
        }
    }
    
    override func pause() {
        self.isPlaying = false
        if isAdPlayback {
            self.adsPlugin.pause()
        } else {
            super.pause()
        }
    }
    
    override func resume() {
        self.isPlaying = true
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
        if self.isPlaying {
            super.play()
        }
        self.delegate?.player(self, failedWith: error)
    }
    
    func adsPlugin(_ adsPlugin: AdsPlugin, managerFailedWith error: String) {
        super.play()
        self.isAdPlayback = false
        self.delegate?.player(self, failedWith: error)
    }
    
    func adsPlugin(_ adsPlugin: AdsPlugin, didReceive event: PKEvent) {
        if event is AdEvents.adDidRequestPause {
            super.pause()
            self.isAdPlayback = true
        } else if event is AdEvents.adDidRequestResume {
            super.play()
            self.isAdPlayback = false
        }
    }
}
