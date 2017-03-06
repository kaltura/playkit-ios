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

        // FairPlay: only looking at the first DRMParams element.
        guard let fpsData = drmData as? FairPlayDRMParams else {
            PKLog.error("Unsupported DRM Data:", drmData)
            readyCallback(AssetError.invalidDrmScheme, nil)
            return
        }

        guard fpsData.fpsCertificate != nil else {
            PKLog.error("Missing FPS Certificate")
            readyCallback(AssetError.noFpsCertificate, nil)
            return
        }

        let asset = AVURLAsset(url: contentUrl)
        
        self.assetLoaderDelegate = AssetLoaderDelegate.configureRemotePlay(asset: asset, drmData: fpsData)
        
        self.avAsset = asset  
        readyCallback(nil, self.avAsset)
    }
}

