//
//  LocalAssetsManager.swift
//  Pods
//
//  Created by Noam Tamim on 15/12/2016.
//
//

import Foundation
import AVFoundation

public class LocalAssetsManager: NSObject {
    let storage: LocalDrmStorage
    var delegates = Set<AssetLoaderDelegate>()
    
    public init(storage: LocalDrmStorage) {
        self.storage = storage
    }
    
    public func prepareForDownload(asset: AVURLAsset, mediaSource: MediaSource) {
        
        PKLog.debug("Preparing asset for download; asset.url:", asset.url)
        guard #available(iOS 10.0, *) else {
            PKLog.error("Offline is only supported on iOS 10+")
            return
            // TODO: this error has to be reported.
        }
        
        guard let drmData = mediaSource.drmData?.first as? FairPlayDRMData else {return}
        
        let resourceLoaderDelegate = AssetLoaderDelegate.configureDownload(asset: asset, drmData: drmData, storage: storage)
        
        self.delegates.update(with: resourceLoaderDelegate)
        
        resourceLoaderDelegate.done =  { (_ error: Error?)->Void in
            self.delegates.remove(resourceLoaderDelegate);
        }
        
    }
    
    
    
    public func createLocalMediaSource(for assetId: String, localURL: URL) -> MediaSource {
        return LocalMediaSource(storage: self.storage, id: assetId, localContentUrl: localURL)
    }
    
    public func createLocalMediaEntry(for assetId: String, localURL: URL) -> MediaEntry {
        let mediaSource = createLocalMediaSource(for: assetId, localURL: localURL)
        return MediaEntry.init(assetId, sources: [mediaSource])
    }
}

public protocol LocalDrmStorage {
    func save(key: String, value: Data) throws
    func load(key: String) throws -> Data?
    func remove(key: String) throws
}

public class DefaultLocalDrmStorage: LocalDrmStorage {
    
    let storageDirectory: URL
    
    public init() throws {
        self.storageDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    }
    
    private func file(_ key: String) -> URL {
        return self.storageDirectory.appendingPathComponent(key)
    }
    
    public func save(key: String, value: Data) throws {
        try value.write(to: file(key), options: .atomic)
    }
    
    public func load(key: String) throws -> Data? {
        return try Data.init(contentsOf: file(key), options: [])
    }
    
    public func remove(key: String) throws {
        try FileManager.default.removeItem(at: file(key))
    }
}

class LocalMediaSource: MediaSource {
    let storage: LocalDrmStorage
    
    init(storage: LocalDrmStorage, id: String, localContentUrl: URL) {
        self.storage = storage
        super.init(id, contentUrl: localContentUrl)
    }
}

