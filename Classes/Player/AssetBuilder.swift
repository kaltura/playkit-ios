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
        
        var selection: (source: MediaSource, handler: AssetHandler.Type)?
        
        // Iterate over all handlers
        let handlers: [AssetHandler.Type] = [DefaultAssetHandler.self, WidevineClassicAssetHandler.self]
        for handler in handlers {
            // Select the first source that the handler can play.
            if let playableSource = sources.first(where: handler.sourceFilter) {
                selection = (source: playableSource, handler: handler)
                break   // don't ask the other handlers
            }
        }
        
        // Check if something was selected
        guard let selected = selection else { 
            PKLog.error("No playable sources")
            readyCallback(AssetError.noPlayableSources, nil)
            return
        }

        // Build the asset
        let handler = selected.handler.init()
        handler.buildAsset(mediaSource: selected.source, readyCallback: readyCallback)
        self.assetHandler = handler
    }
}

protocol AssetHandler {
    init()
    static var sourceFilter: (MediaSource)->Bool {get}
    func buildAsset(mediaSource: MediaSource, readyCallback: (Error?, AVAsset?)->Void)
}

enum AssetError : Error {
    case noFpsCertificate
    case invalidDrmScheme
    case invalidContentUrl(URL?)
    case noPlayableSources
}
