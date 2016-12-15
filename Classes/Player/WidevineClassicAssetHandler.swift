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
        return false // not implemented
        // This function should return true if the source is a Widevine Classic file.
    }

    internal func buildAsset(mediaSource: MediaSource, readyCallback: (Error?, AVAsset?) -> Void) {
        // TODO: start Widevine license acq, call play, build asset
        
    }

    required init() {
        
    }
}


