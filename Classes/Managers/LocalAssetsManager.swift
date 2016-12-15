//
//  LocalAssetsManager.swift
//  Pods
//
//  Created by Noam Tamim on 15/12/2016.
//
//

import Foundation
import AVFoundation

public protocol LocalDrmStorage {
    func save(key: String, value: String)
    func load(key: String) -> String
    func remove(key: String)
}

public class DefaultLocalDrmStorage: LocalDrmStorage {
    public func save(key: String, value: String) {
        
    }
    
    public func load(key: String) -> String {
        return "TODO"
    }
    
    public func remove(key: String) {
        
    }
}

public class LocalAssetsManager: NSObject {
    let storage: LocalDrmStorage
    var resourceLoaderDelegate: AssetLoaderDelegate?
    
    public init(storage: LocalDrmStorage? = nil) {
        self.storage = storage ?? DefaultLocalDrmStorage()
    }
    
    public func prepareForDownload(asset: AVURLAsset, assetId: String, mediaSource: MediaSource) {
        // TODO: set delegate, preloadEligibleKeys
        guard let drmData = mediaSource.drmData as? FairPlayDRMData else {return}
        
        self.resourceLoaderDelegate = AssetLoaderDelegate.configureAsset(asset: asset, assetName: assetId, drmData: drmData)
        
        if #available(iOS 9.0, *) {
            asset.resourceLoader.preloadsEligibleContentKeys = true
        } else {
            // Fallback on earlier versions
        }
        
    }
    
    public func createLocalMediaSource(for assetId: String, localURL: URL) -> MediaSource {
        // TODO
        return MediaSource(dict: [
            "id": assetId,
            "url": localURL,
            "drmData": [
                "persisted": true
            ]
            ])
    }
}
