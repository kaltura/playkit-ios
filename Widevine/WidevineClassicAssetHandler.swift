//
//  WidevineClassicAssetHandler.swift
//  Pods
//
//  Created by Noam Tamim on 30/11/2016.
//
//

import Foundation
import AVFoundation

class WidevineClassicAssetHandler: AssetHandler {
    
    static let sourceFilter = { (_ src: MediaSource) -> Bool in
        
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


    internal func buildAsset(mediaSource: MediaSource, readyCallback: @escaping (Error?, AVAsset?) -> Void) {
        
        guard let contentUrl = mediaSource.contentUrl else {
            PKLog.error("Invalid media: no url")
            readyCallback(AssetError.invalidContentUrl(nil), nil)
            return
        }
        
        if let localSource = mediaSource as? LocalMediaSource {
            PKLog.debug("Creating local asset")
            let asset = AVURLAsset(url: contentUrl)

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


