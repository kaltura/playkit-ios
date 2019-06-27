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
    /// The player's media config start time.
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

public protocol AdsPlugin: PKPlugin {
    var dataSource: AdsPluginDataSource? { get set }
    var delegate: AdsPluginDelegate? { get set }
    /// Is ad currently playing.
    var isAdPlaying: Bool { get }
    /// Whether or not the pre-roll should be played upon start position different than 0.
    var startWithPreroll: Bool { get }
    /// Request ads from the server.
    func requestAds() throws
    /// Resume ad.
    func resume()
    /// Pause ad.
    func pause()
    /// Ad content complete.
    func contentComplete()
    /// Destroy the ads manager.
    func destroyManager()
    /// Called after player called `super.play()`.
    func didPlay()
    /// Called when play() or resume() was called.
    /// Used to make the neccery checks with the ads plugin if can play or resume the content.
    func didRequestPlay(ofType type: PlayType)
    /// Called when entering the background.
    func didEnterBackground()
    /// Called when coming back from background.
    func willEnterForeground()
}

#if os(iOS)
public protocol PIPEnabledAdsPlugin: AdsPlugin, AVPictureInPictureControllerDelegate {
    var pipDelegate: AVPictureInPictureControllerDelegate? { get set }
}
#endif
