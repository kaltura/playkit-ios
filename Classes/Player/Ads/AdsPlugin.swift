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
import AVKit

public enum PlayType: CustomStringConvertible {
    case play, resume
    
    public var description: String {
        switch self {
        case .play:
            return "Play"
        case .resume:
            return "Resume"
        }
    }
}

public protocol AdsPluginDataSource : class {
    func adsPluginShouldPlayAd(_ adsPlugin: AdsPlugin) -> Bool
    /// the player's media config start time.
    var playAdsAfterTime: TimeInterval { get }
}

public protocol AdsPluginDelegate : class {
    func adsPlugin(_ adsPlugin: AdsPlugin, loaderFailedWith error: String)
    func adsPlugin(_ adsPlugin: AdsPlugin, managerFailedWith error: String)
    func adsPlugin(_ adsPlugin: AdsPlugin, didReceive event: PKEvent)
    
    /// called when ads request was timed out, telling the player if it should start play afterwards.
    func adsRequestTimedOut(shouldPlay: Bool)
    
    /// called when the plugin wants the player to start play.
    func play(_ playType: PlayType)
}

public protocol AdsPlugin: PKPlugin, AVPictureInPictureControllerDelegate {
    var dataSource: AdsPluginDataSource? { get set }
    var delegate: AdsPluginDelegate? { get set }
    var pipDelegate: AVPictureInPictureControllerDelegate? { get set }
    /// is ad playing currently.
    var isAdPlaying: Bool { get }
    
    /// request ads from the server.
    func requestAds() throws
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
    func didRequestPlay(ofType type: PlayType)
    
    /// called when entered to background
    func didEnterBackground()
    /// called when coming back from background
    func willEnterForeground()
}

