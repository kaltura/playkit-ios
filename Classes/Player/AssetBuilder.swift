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

    func getPreferredMediaSource() -> (MediaSource, AssetHandler.Type)? {
        
        guard let sources = mediaEntry.sources else {
            PKLog.error("no media sources in mediaEntry!")
            return nil
        }
        
        let defaultHandler = DefaultAssetHandler.self
        
        // Preference: Local, HLS, FPS*, MP4, WVM*
        
        if let source = sources.first(where: {$0 is LocalMediaSource}) {
            if source.fileExt == "wvm" {
                return (source, DRMSupport.widevineClassicHandler!)
            } else {
                return (source, defaultHandler)
            }
        }
        
        if DRMSupport.fairplay {
            if let source = sources.first(where: {$0.fileExt=="m3u8"}) {
                return (source, defaultHandler)
            }
        } else {
            if let source = sources.first(where: {$0.fileExt=="m3u8" && ($0.drmData == nil || $0.drmData!.isEmpty) }) {
                return (source, defaultHandler)
            }
        }
        
        if let source = sources.first(where: {$0.fileExt=="mp4"}) {
            return (source, defaultHandler)
        }
        
        if DRMSupport.widevineClassic, let source = sources.first(where: {$0.fileExt=="wvm"}) {
            return (source, DRMSupport.widevineClassicHandler!)
        }
        
        PKLog.error("no playable media sources!")
        return nil
    }

    func build(readyCallback: @escaping (Error?, AVAsset?)->Void) -> Void {
        
        guard let (source, handlerClass) = getPreferredMediaSource() else {
            PKLog.error("No playable sources")
            readyCallback(AssetError.noPlayableSources, nil)
            return
        }
        
        // Build the asset
        let handler = handlerClass.init()
        handler.buildAsset(mediaSource: source, readyCallback: readyCallback)
        self.assetHandler = handler
    }
}

protocol AssetHandler {
    init()
    func buildAsset(mediaSource: MediaSource, readyCallback: @escaping (Error?, AVAsset?)->Void)
}

protocol RefreshableAssetHandler: AssetHandler {
    func shouldRefreshAsset(mediaSource: MediaSource, refreshCallback: @escaping (Bool)->Void)
    func refreshAsset(mediaSource: MediaSource)
}

enum AssetError : Error {
    case noFpsCertificate
    case noLicenseUri
    case invalidDrmScheme
    case invalidContentUrl(URL?)
    case noPlayableSources
}

class DRMSupport {
    // FairPlay is not available in simulators and before iOS8
    static let fairplay: Bool = {
        if TARGET_OS_SIMULATOR==0, #available(iOS 8, *) {
            return true
        } else {
            return false
        }
    }()
    
    // FairPlay is not available in simulators and is only downloadable in iOS10 and up.
    static let fairplayOffline: Bool = {
        if TARGET_OS_SIMULATOR==0, #available(iOS 10, *) {
            return true
        } else {
            return false
        }
    }()
    
    // Widevine is optional (and not available in simulators)
    static let widevineClassic = widevineClassicHandler != nil
    
    // Preload the Widevine Classic Handler, if available
    static let widevineClassicHandler: AssetHandler.Type? = {
        if TARGET_OS_SIMULATOR != 0 {
            return nil
        }
        return NSClassFromString("PlayKit.WidevineClassicAssetHandler") as? AssetHandler.Type
    }()
}



