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
        
        // The only other option is HLS
        if ext == "wvm" {
            return true
        }
        
        PKLog.error("pathExtension is not wvm")
        return false
    }


    internal func buildAsset(mediaSource: MediaSource, readyCallback: @escaping (Error?, AVAsset?) -> Void) {
        // TODO: start Widevine license acq, call play, build asset
        let drmData = mediaSource.drmData?.first
        WidevineClassicCDM.playAsset(mediaSource.contentUrl?.absoluteString, withLicenseUri: drmData!.licenseUri!.absoluteString) {  (_ playbackURL:String?)->Void  in
        
            DispatchQueue.main.async {
                readyCallback(nil, AVURLAsset(url: URL(string: playbackURL!)!))
            }
           
        }
    }

    required init() {
    
    }
}


