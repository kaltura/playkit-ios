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

class DefaultAssetHandler: AssetHandler {
    
    var assetLoaderDelegate: AssetLoaderDelegate?
    var avAsset: AVURLAsset?
    
    required init() {
        
    }
    
    func build(from mediaSource: PKMediaSource, readyCallback: @escaping (Error?, AVURLAsset?) -> Void) {

        guard let contentUrl = mediaSource.contentUrl, let playbackUrl = mediaSource.playbackUrl else {
            PKLog.error("Invalid media: no url")
            readyCallback(AssetError.invalidContentUrl(nil), nil)
            return
        }
        
        let headers = ["User-Agent": PlayKitManager.clientTag]
        let assetOptions = ["AVURLAssetHTTPHeaderFieldsKey": headers]
        
        if let localSource = mediaSource as? LocalMediaSource {
            PKLog.debug("Creating local asset")
            let asset = AVURLAsset(url: contentUrl, options: assetOptions)
            
            
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
            readyCallback(nil, AVURLAsset(url: playbackUrl, options: assetOptions))
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

        let asset = AVURLAsset(url: playbackUrl, options: assetOptions)
        
        self.assetLoaderDelegate = AssetLoaderDelegate.configureRemotePlay(asset: asset, drmData: fpsData)
        
        self.avAsset = asset  
        readyCallback(nil, self.avAsset)
    }
}

