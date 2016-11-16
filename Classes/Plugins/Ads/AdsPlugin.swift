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
    func adsPlugin(_ adsPlugin: AdsPlugin, failedWith error: String)
    func adsPlugin(_ adsPlugin: AdsPlugin, didReceive event: PlayerEventType, with eventData: Any?)
}

protocol AdsPlugin: Plugin, AVPictureInPictureControllerDelegate {
    var dataSource: AdsPluginDataSource! { get set }
    var delegate: AdsPluginDelegate? { get set }
    var pipDelegate: AVPictureInPictureControllerDelegate? { get set }
    
    func requestAds()
    func start(showLoadingView: Bool) -> Bool
    func resume()
    func pause()
    func contentComplete()
}

