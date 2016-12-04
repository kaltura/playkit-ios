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
    required init() {
        
    }
    func buildAsset(mediaSource: MediaSource, readyCallback: (AVAsset?)->Void) {
        if let url = mediaSource.contentUrl {
            readyCallback(AVURLAsset(url: url))
        } else {
            readyCallback(nil)
        }
    }
}
