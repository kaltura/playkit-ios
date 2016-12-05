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

    func build(readyCallback: (Error?, AVAsset?)->Void) -> Void {
        
        // Select source and handler
        guard let sources = mediaEntry.sources else { return }
        let selectedSource = sources[0]

        let handlerClass = DefaultAssetHandler.self

        let handler = handlerClass.init()

        handler.buildAsset(mediaSource: selectedSource, readyCallback: readyCallback)
    }
}

protocol AssetHandler {
    init()
    func buildAsset(mediaSource: MediaSource, readyCallback: (Error?, AVAsset?)->Void)
}


enum AssetHandlerResult {
    case asset(AVAsset)
    case error(Error)
}

enum AssetError : Error {
    case noFpsCertificate
    case invalidDrmScheme
    case invalidContentUrl(URL?)
}
