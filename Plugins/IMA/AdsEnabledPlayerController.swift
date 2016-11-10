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

class AdsEnabledPlayerController : PlayerDecoratorBase, AdsPluginDataSource, AdsPluginDelegate {
    
    var isAdPlayback = false
    var adsPlugin: AdsPlugin!
    var adTagUrl: String?
    var adTagsTimes: [TimeInterval : String]?
    
    /*var player: Player! {
        didSet {
            self.subscribe(to: PlayerEventType.item_did_play_to_end_time, using: { (eventData: AnyObject?) -> Void in
                self.adsPlugin.contentComplete()
            })
        }
    }*/
    
    override var dataSource: PlayerDataSource? {
        didSet {
            self.adsPlugin.dataSource = self
            if self.adTagUrl != "" {
                self.adsPlugin.requestAds(with: self.adTagUrl!)
            } else if self.adTagsTimes != nil {
                self.adsPlugin.tagsTimes = self.adTagsTimes
            }
        }
    }
    
    override func play() {
        if self.adTagUrl != "" {
            self.adsPlugin.start(showLoadingView: true)
        } else {
            super.play()
        }
    }
    
    override func pause() {
        if isAdPlayback {
            self.adsPlugin.pause()
        } else {
            super.pause()
        }
    }
    
    override func resume() {
        if isAdPlayback {
            self.adsPlugin.resume()
        } else {
            super.resume()
        }
    }

    override func destroy() {
        super.destroy()
        self.adsPlugin.destroy()
    }
    
    /*var avPlayer: AVPlayer? {
        get {
            return nil//self.player.avPlayer
        }
    }*/
    
        
    /*func createPiPController(with delegate: AVPictureInPictureControllerDelegate) -> AVPictureInPictureController? {
        self.adsPlugin.pipDelegate = delegate
        return self.player.createPiPController(with: self.adsPlugin)
    }*/
    
    private func convertToPlayerEvent(_ event: AdsPluginEventType) -> PlayerEventType {
        switch event {
        case .ad_break_ready:
            return PlayerEventType.ad_break_ready
        case .ad_break_ended:
            return PlayerEventType.ad_break_ended
        case .ad_break_started:
            return PlayerEventType.ad_break_started
        case .all_ads_completed:
            return PlayerEventType.all_ads_completed
        case .clicked:
            return PlayerEventType.clicked
        case .complete:
            return PlayerEventType.complete
        case .cuepoints_changed:
            return PlayerEventType.cuepoints_changed
        case .first_quartile:
            return PlayerEventType.first_quartile
        case .loaded:
            return PlayerEventType.loaded
        case .log:
            return PlayerEventType.log
        case .midpoint:
            return PlayerEventType.midpoint
        case .pause:
            return PlayerEventType.pause
        case .resume:
            return PlayerEventType.resume
        case .skipped:
            return PlayerEventType.skipped
        case .started:
            return PlayerEventType.started
        case .stream_loaded:
            return PlayerEventType.stream_loaded
        case .tapped:
            return PlayerEventType.tapped
        case .third_quartile:
            return PlayerEventType.third_quartile
        }
    }

    func adsPluginVideoView(_ adsPlugin: AdsPlugin) -> UIView {
        return self.dataSource!.playerVideoView(self)
    }
    
    func adsPluginCanPlayAd(_ adsPlugin: AdsPlugin) -> Bool {
        return self.dataSource!.playerCanPlayAd(self)
    }
    
    func adsPluginCompanionView(_ adsPlugin: AdsPlugin) -> UIView? {
        return self.dataSource!.playerCompanionView(self)
    }
    
    func adsPluginWebOpenerPresentingController(_ adsPlugin: AdsPlugin) -> UIViewController? {
        return self.dataSource!.playerAdWebOpenerPresentingController(self)
    }
    
    func adsPluginDidRequestContentPause(_ adsPlugin: AdsPlugin) {
        self.isAdPlayback = true
        self.delegate?.playerAdDidRequestContentPause(self)
    }
    
    func adsPluginDidRequestContentResume(_ adsPlugin: AdsPlugin) {
        self.isAdPlayback = false
        self.delegate?.playerAdDidRequestContentResume(self)
    }
    
    func adsPlugin(_ adsPlugin: AdsPlugin, failedWith error: String) {
        self.isAdPlayback = false
        self.delegate?.player(self, failedWith: error)
    }
    
    func adsPlugin(_ adsPlugin: AdsPlugin, didReceive adEvent: AdsPluginEventType) {
        self.delegate?.player(self, didReceive: self.convertToPlayerEvent(adEvent))
    }
    
    func adsPlugin(_ adsPlugin: AdsPlugin, adDidProgressToTime mediaTime: TimeInterval, totalTime: TimeInterval) {
        self.delegate?.player(self, adDidProgressToTime: mediaTime, totalTime: totalTime)
    }
    
    func adsPlugin(_ adsPlugin: AdsPlugin, webOpenerDidOpenInAppBrowser webOpener: NSObject!) {
        self.delegate?.player(self, adWebOpenerDidOpenInAppBrowser: webOpener)
    }
    
    func adsPlugin(_ adsPlugin: AdsPlugin, webOpenerWillOpenInAppBrowser webOpener: NSObject!) {
        self.delegate?.player(self, adWebOpenerWillOpenInAppBrowser: webOpener)
    }
    
    func adsPlugin(_ adsPlugin: AdsPlugin, webOpenerDidCloseInAppBrowser webOpener: NSObject!) {
        self.delegate?.player(self, adWebOpenerDidCloseInAppBrowser: webOpener)
    }
    
    func adsPlugin(_ adsPlugin: AdsPlugin, webOpenerWillCloseInAppBrowser webOpener: NSObject!) {
        self.delegate?.player(self, adWebOpenerWillCloseInAppBrowser: webOpener)
    }
    
    func adsPlugin(_ adsPlugin: AdsPlugin, webOpenerWillOpenExternalBrowser webOpener: NSObject!) {
        self.delegate?.player(self, adWebOpenerWillOpenInAppBrowser: webOpener)
    }
}
