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

    
    func buildAsset(mediaSource: MediaSource, readyCallback: @escaping (Error?, AVAsset?)->Void) {

        guard let contentUrl = mediaSource.contentUrl else {
            PKLog.error("Invalid media: no url")
            readyCallback(AssetError.invalidContentUrl(nil), nil)
            return
        }
        
        if let localSource = mediaSource as? LocalMediaSource {
            PKLog.debug("Creating local asset")
            let asset = AVURLAsset(url: contentUrl)
            
            
            if #available(iOS 10.0, *) {
                self.assetLoaderDelegate = AssetLoaderDelegate.configureLocalPlay(asset: asset, storage: localSource.storage)
            } else {
                // On earlier versions, this will only work for non-FairPlay content.
                PKLog.warning("Preparing local asset in iOS<10:", contentUrl)
            }
            
            self.avAsset = asset  
            readyCallback(nil, self.avAsset)
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
        
        self.assetLoaderDelegate = AssetLoaderDelegate.configureRemotePlay(asset: asset, drmData: fpsData)
        
        self.avAsset = asset  
        readyCallback(nil, self.avAsset)
    }
}

