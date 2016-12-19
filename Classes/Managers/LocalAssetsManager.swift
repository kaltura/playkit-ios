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
    func save(key: String, value: Data)
    func load(key: String) -> Data?
    func remove(key: String)
}

public class DefaultLocalDrmStorage: LocalDrmStorage {
    
    let storageDirectory: URL
    
    init() throws {
        self.storageDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    }
    
    private func file(_ key: String) -> URL {
        return self.storageDirectory.appendingPathComponent(key)
    }
    
    public func save(key: String, value: Data) {
        try? value.write(to: file(key), options: .atomic)
    }
    
    public func load(key: String) -> Data? {
        return try? Data.init(contentsOf: file(key), options: [])
    }
    
    public func remove(key: String) {
        try? FileManager.default.removeItem(at: file(key))
    }
}

class LocalMediaSource: MediaSource {
    let storage: LocalDrmStorage
    
    init(storage: LocalDrmStorage, dict: [String : Any]) {
        self.storage = storage
        super.init(json: dict)
    }
}

public class LocalAssetsManager: NSObject {
    let storage: LocalDrmStorage
    var resourceLoaderDelegate: AssetLoaderDelegate?
    
    public init(storage: LocalDrmStorage? = nil) {
        if let storage = storage {
            self.storage = storage
        } else {
            
            self.storage = try! DefaultLocalDrmStorage()
        }
    }
    
    public func prepareForDownload(asset: AVURLAsset, assetId: String, mediaSource: MediaSource) {

        guard #available(iOS 10.0, *) else {
            PKLog.error("Offline is only supported on iOS 10+")
            return
            // TODO: this error has to be reported.
        }
        
        guard let drmData = mediaSource.drmData?.first as? FairPlayDRMData else {return}

        let resourceLoaderDelegate = AssetLoaderDelegate.configureAsset(asset: asset, assetName: assetId, drmData: drmData, shouldPersist: true)
        
        resourceLoaderDelegate.storage = self.storage
        self.resourceLoaderDelegate = resourceLoaderDelegate
        
    }
    
    
    
    public func createLocalMediaSource(for assetId: String, localURL: URL) -> MediaSource {
        // TODO
                
        var source = LocalMediaSource(storage: self.storage, dict: [
            "id": assetId,
            "url": localURL,
            ])
        
        return source
    }
}