//
//  AdsPlugin.swift
//  Pods
//
//  Created by Vadim Kononov on 14/11/2016.
//
//

import Foundation
import AVKit

protocol AdsPluginDataSource : class {
    func adsPluginShouldPlayAd(_ adsPlugin: AdsPlugin) -> Bool
    /// the player's media config start time.
    var playAdsAfterTime: TimeInterval { get }
}

protocol AdsPluginDelegate : class {
    func adsPlugin(_ adsPlugin: AdsPlugin, loaderFailedWith error: String)
    func adsPlugin(_ adsPlugin: AdsPlugin, managerFailedWith error: String)
    func adsPlugin(_ adsPlugin: AdsPlugin, didReceive event: PKEvent)
    /// called when ads request was timed out, telling the player if it should start play afterwards.
    func adsRequestTimedOut(shouldPlay: Bool)
    /// called when the plugin wants the player to start play.
    func play(_ playType: AdsEnabledPlayerController.PlayType)
}

protocol AdsPlugin: PKPlugin, AVPictureInPictureControllerDelegate {
    weak var dataSource: AdsPluginDataSource? { get set }
    weak var delegate: AdsPluginDelegate? { get set }
    var pipDelegate: AVPictureInPictureControllerDelegate? { get set }
    /// is ad playing currently.
    var isAdPlaying: Bool { get }
    
    /// request ads from the server.
    func requestAds()
    /// resume ad
    func resume()
    /// pause ad
    func pause()
    /// ad content complete
    func contentComplete()
    /// destroy the ads manager
    func destroyManager()
    /// called after player called `super.play()`
    func didPlay()
    /// called when play() or resume() was called.
    /// used to make the neccery checks with the ads plugin if can play or resume the content.
    func didRequestPlay(ofType type: AdsEnabledPlayerController.PlayType)
    
    /// called when entered to background
    func didEnterBackground()
    /// called when coming back from background
    func willEnterForeground()
}

