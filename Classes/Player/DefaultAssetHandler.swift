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
    func buildAsset(mediaSource: MediaSource, readyCallback: (Error?, AVAsset?)->Void) {

        guard let contentUrl = mediaSource.contentUrl else {
            PKLog.error("Invalid media: no url")
            readyCallback(AssetError.invalidContentUrl(nil), nil)
            return
        }

        if mediaSource.drmData == nil {
            readyCallback(nil, AVURLAsset(url: contentUrl))
            return
        }

        // FairPlay
        guard let fpsData = mediaSource.drmData as? FairPlayDRMData else {
            PKLog.error("Unsupported DRM Data:", mediaSource.drmData)
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
        self.assetLoaderDelegate = AssetLoaderDelegate.configureAsset(asset: asset, assetName: mediaSource.id, drmData: fpsData)
        self.avAsset = asset  
        readyCallback(nil, self.avAsset)
    }
}

