//
//  DefaultAssetHandler.swift
//  Pods
//
//  Created by Noam Tamim on 30/11/2016.
//
//

import Foundation
import AVFoundation

class DefaultAssetHandler: AssetHandler {
    
    var assetLoaderDelegate: AssetLoaderDelegate?
    var avAsset: AVURLAsset?
    
    required init() {
        
    }
    
    static let sourceFilter = { (_ src: MediaSource) -> Bool in
        
        // FIXME: extension is not the best criteria here, use format when that's available. 
        guard let ext = src.contentUrl?.pathExtension else {
            return false
        }
        
        // mp4 is always supported
        if ext == "mp4" {
            return true
        }
        
        // 'movpkg' was downloaded here.
        if ext == "movpkg" {
            return true
        }
        
        // The only other option is HLS
        if ext != "m3u8" {
            return false
        }
        
        // DRM is not supported on simulators
        if src.drmData != nil && TARGET_OS_SIMULATOR != 0 {
            return false
        }
        
        // Source is HLS, with or without DRM.
        return true
    }

    
    func buildAsset(mediaSource: MediaSource, readyCallback: (Error?, AVAsset?)->Void) {

        guard let contentUrl = mediaSource.contentUrl else {
            PKLog.error("Invalid media: no url")
            readyCallback(AssetError.invalidContentUrl(nil), nil)
            return
        }

        
        guard let drmData = mediaSource.drmData?.first else {
            PKLog.debug("Creating clear AVURLAsset")
            readyCallback(nil, AVURLAsset(url: contentUrl))
            return
        }

        // FairPlay: only looking at the first DRMData element.
        guard let fpsData = drmData as? FairPlayDRMData else {
            PKLog.error("Unsupported DRM Data:", drmData)
            readyCallback(AssetError.invalidDrmScheme, nil)
            return
        }

        guard let fpsCertificate = fpsData.fpsCertificate else {
            PKLog.error("Missing FPS Certificate")
            readyCallback(AssetError.noFpsCertificate, nil)
            return
        }

        let assetName = mediaSource.id
        
        let asset = AVURLAsset(url: contentUrl)
        
        let persisted = mediaSource is LocalMediaSource
        
        if persisted {
            if #available(iOS 10.0, *) {
                asset.resourceLoader.preloadsEligibleContentKeys = true
            } else {
                // Fallback on earlier versions
            }
        }
        self.assetLoaderDelegate = AssetLoaderDelegate.configureAsset(asset: asset, assetName: assetName, drmData: fpsData, shouldPersist: persisted)
        
        self.avAsset = asset  
        readyCallback(nil, self.avAsset)
    }
}

