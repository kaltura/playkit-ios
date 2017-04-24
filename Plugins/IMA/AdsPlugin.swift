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
    var isAdPlaying: Bool { get }
    
    func requestAds()
    func resume()
    func pause()
    func contentComplete()
    func destroyManager()
    /// called after player called `super.play()`
    func didPlay()
    /// called when play() or resume() was called.
    /// used to make the neccery checks with the ads plugin if can play or resume the content.
    func didRequestPlay(ofType type: AdsEnabledPlayerController.PlayType)
}

