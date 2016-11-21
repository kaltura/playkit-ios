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
    
    init(adsPlugin: AdsPlugin) {
        super.init()
        self.adsPlugin = adsPlugin
    }
    
    override func setPlayer(_ player: Player!) {
        super.setPlayer(player)
        
        /*self.subscribe(to: PlayerEventType.item_did_play_to_end_time, using: { (eventData: AnyObject?) -> Void in
            self.adsPlugin.contentComplete()
        })*/
    }
    
    override var dataSource: PlayerDataSource? {
        didSet {
            self.adsPlugin.dataSource = self
            self.adsPlugin.requestAds()
        }
    }
    
    override var delegate: PlayerDelegate? {
        didSet {
            self.adsPlugin.delegate = self
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
        return self.dataSource!.playerShouldPlayAd(self)
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
    
    func adsPlugin(_ adsPlugin: AdsPlugin, didReceive event: PlayerEventType, with eventData: Any?) {
        if event == PlayerEventType.ad_did_request_pause {
            super.pause()
            self.isAdPlayback = true
        } else if event == PlayerEventType.ad_did_request_resume {
            super.play()
            self.isAdPlayback = false
        }
        self.delegate?.player(self, didReceive: event, with: eventData)
    }
}
