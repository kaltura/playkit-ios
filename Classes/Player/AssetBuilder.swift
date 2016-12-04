//
//  AssetBuilder.swift
//  Pods
//
//  Created by Noam Tamim on 30/11/2016.
//
//

import Foundation
import AVFoundation

class AssetBuilder {
    
    let mediaEntry: MediaEntry
    var assetHandler: AssetHandler?
    
    init(mediaEntry: MediaEntry) {
        self.mediaEntry = mediaEntry
    }
    
    func build(readyCallback: (AVAsset?)->Void) -> Void {
        
        // Select source and handler
        guard let sources = mediaEntry.sources else { return  }
        let selectedSource = sources[0]

        let handlerClass = DefaultAssetHandler.self

        let handler = handlerClass.init()

        handler.buildAsset(mediaSource: selectedSource, readyCallback: readyCallback)
    }
}


protocol AssetHandler {
    init()
    func buildAsset(mediaSource: MediaSource, readyCallback: (AVAsset?)->Void)
}


let defaultAssetHandler = { (mediaSource: MediaSource, ready: (AVAsset?)->Void) in
    if let url = mediaSource.contentUrl {
        ready(AVURLAsset(url: url))
    } else {
        ready(nil)
    }
}





