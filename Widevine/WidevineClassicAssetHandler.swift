// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import Foundation
import AVFoundation

typealias ReadyCallback = (Error?, AVURLAsset?) -> Void
typealias RefreshCallback = (Bool) -> Void

class WidevineClassicAssetHandler: RefreshableAssetHandler {
    
    var refreshCallback: RefreshCallback?
    
    static let sourceFilter = { (_ src: PKMediaSource) -> Bool in
        
        // FIXME: extension is not the best criteria here, use format when that's available.
        guard let ext = src.contentUrl?.pathExtension else {
            return false
        }
        
        // DRM is not supported on simulators
        if src.drmData != nil && TARGET_OS_SIMULATOR != 0 {
            PKLog.warning("DRM is not supported on simulators")
            return false
        }
        
        // Only support wvm files
        if ext == "wvm" {
            return true
        }
        
        return false
    }
    
    func shouldRefreshAsset(mediaSource: MediaSource, refreshCallback: @escaping RefreshCallback) {
        self.refreshCallback = refreshCallback

        guard let contentUrl = mediaSource.contentUrl else {
            PKLog.error("Invalid media: no url")
            refreshCallback(false)
            return
        }
        
        guard (mediaSource.drmData?.first?.licenseUri) != nil else {
            PKLog.error("Missing licenseUri")
            refreshCallback(false)
            return
        }
        
        WidevineClassicHelper.shouldRefreshAsset(contentUrl.absoluteString) { (shouldRefresh) in
            if shouldRefresh {
                refreshCallback(true)
            }
        }
    }
    
    func refreshAsset(mediaSource: PKMediaSource) {
        
        guard let contentUrl = mediaSource.contentUrl else {
            PKLog.error("Invalid media: no url")
            return
        }
        
        // WidevineClassicHandler.playAsset here will cause the stream to be closed and reopened (WV_Stop, WV_Play).
        // Since we already have LicenseUri no reason to send it again.
        WidevineClassicHelper.playAsset(contentUrl.absoluteString, withLicenseUri: nil) {  (_ playbackURL: String?) -> Void  in
            if playbackURL == "" {
                PKLog.error("Invalid media: no url")
                self.refreshCallback?(false)
                return
            }
            
            guard let playbackURL = playbackURL else {
                PKLog.error("Invalid media: no url")
                self.refreshCallback?(false)
                return
            }
            
            DispatchQueue.main.async {
                PKLog.debug("widevine classic:: callback url:\(playbackURL)")
                self.refreshCallback?(true)
            }
        }
    }
    
    func buildAsset(mediaSource: MediaSource, readyCallback: @escaping ReadyCallback) {
        guard let contentUrl = mediaSource.contentUrl else {
            PKLog.error("Invalid media: no url")
            readyCallback(AssetError.invalidContentUrl(nil), nil)
            return
        }
        
        if let localSource = mediaSource as? LocalMediaSource {
            PKLog.debug("Creating local asset")

            WidevineClassicHelper.playLocalAsset(localSource.contentUrl?.absoluteString) { (_ playbackURL:String?) in
                guard let playbackURL = playbackURL else {
                    PKLog.error("Invalid media: no url")
                    readyCallback(AssetError.invalidContentUrl(nil), nil)
                    return
                }
                
                DispatchQueue.main.async {
                    PKLog.debug("widevine classic:: callback url:\(playbackURL)")
                    readyCallback(nil, AVURLAsset(url: URL(string: playbackURL)!))
                }
            }
            
            return
        }
        
        guard let drmData = mediaSource.drmData?.first else {
            PKLog.error("Invalid drm data")
            readyCallback(AssetError.noPlayableSources, nil)
            return
        }
        
        guard let licenseUri = drmData.licenseUri else {
            PKLog.error("Missing licenseUri")
            readyCallback(AssetError.noLicenseUri, nil)
            return
        }
        
        PKLog.trace("playAsset:: url: \(contentUrl.absoluteString), uri: \(licenseUri.absoluteString)")
       
        WidevineClassicHelper.playAsset(contentUrl.absoluteString, withLicenseUri: licenseUri.absoluteString) {  (_ playbackURL:String?)->Void  in
            
            guard let playbackURL = playbackURL else {
                PKLog.error("Invalid media: no url")
                readyCallback(AssetError.invalidContentUrl(nil), nil)
                return
            }
            
            DispatchQueue.main.async {
                PKLog.debug("widevine classic:: callback url:\(playbackURL)")
                readyCallback(nil, AVURLAsset(url: URL(string: playbackURL)!))
            }
        }
    }
    
    required init() {}
}


