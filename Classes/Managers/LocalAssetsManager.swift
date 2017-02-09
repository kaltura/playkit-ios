//
//  LocalAssetsManager.swift
//  Pods
//
//  Created by Noam Tamim on 15/12/2016.
//
//

import Foundation
import AVFoundation

/// Manage local (downloaded) assets.
public class LocalAssetsManager: NSObject {
    let storage: LocalDataStore
    var delegates = Set<AssetLoaderDelegate>()
    
    private override init() {
        fatalError("Private initializer, use one of the factory methods")
    }
    
    /**
     Create a new LocalAssetsManager for DRM-protected content. 
     Uses the default data-store.
     */
    public static func managerWithDefaultDataStore() -> LocalAssetsManager {
        return LocalAssetsManager(storage: DefaultLocalDataStore.defaultDataStore())
    }
    
    /**
     Create a new LocalAssetsManager for DRM-protected content.
     
     - Parameter storage: data store. 
     */
    public static func manager(storage: LocalDataStore) -> LocalAssetsManager {
        return LocalAssetsManager(storage: storage)
    }
    
    /**
     Create a new LocalAssetsManager for non-DRM content.
    */
    public static func manager() -> LocalAssetsManager {
        return LocalAssetsManager(storage: nil)
    }
    
    /**
     Create a new LocalAssetsManager.
     
     - Parameter storage: data store. Used for DRM data, and may only be nil if DRM is not used.
    */
    private init(storage: LocalDataStore?) {
        self.storage = storage ?? NullStore.instance
    }

    /**
     Prepare an AVURLAsset for download via AVAssetDownloadTask.
     Note that this is only relevant for FairPlay assets, and does not do anything otherwise.
     
     - Parameters:
        - asset: an AVURLAsset, ready to be downloaded
        - mediaSource: the original source for the asset. mediaSource.contentUrl and asset.url should point at the same file.
    */
    public func prepareForDownload(asset: AVURLAsset, mediaSource: MediaSource) {
        
        // This function is a noop if no DRM data or DRM is not FairPlay.
        guard let drmData = mediaSource.drmData?.first as? FairPlayDRMData else {return}

        PKLog.debug("Preparing asset for download; asset.url:", asset.url)
        
        guard #available(iOS 10, *), DRMSupport.fairplayOffline else {
            PKLog.error("Downloading FairPlay content is not supported on device")
            return
        }

        let resourceLoaderDelegate = AssetLoaderDelegate.configureDownload(asset: asset, drmData: drmData, storage: storage)

        self.delegates.update(with: resourceLoaderDelegate)

        resourceLoaderDelegate.done =  { (_ error: Error?)->Void in
            self.delegates.remove(resourceLoaderDelegate);
        }

    }

    /// Create a MediaSource for a local asset. This allows the player to play a downloaded asset.
    private func createLocalMediaSource(for assetId: String, localURL: URL) -> MediaSource {
        return LocalMediaSource(storage: self.storage, id: assetId, localContentUrl: localURL)
    }

    /// Create a MediaEntry for a local asset. This is a convenience function that wraps the result of
    /// `createLocalMediaSource(for:localURL:)` with a MediaEntry.
    public func createLocalMediaEntry(for assetId: String, localURL: URL) -> MediaEntry {
        let mediaSource = createLocalMediaSource(for: assetId, localURL: localURL)
        return MediaEntry.init(assetId, sources: [mediaSource])
    }
    
    /// Get the preferred MediaSource for download purposes. This function takes into account
    /// the capabilities of the device.
    public func getPreferredDownloadableMediaSource(for mediaEntry: MediaEntry) -> MediaSource? {

        guard let sources = mediaEntry.sources else {return nil}
        
        // On iOS 10 and up: HLS (clear or FP), MP4, WVM
        // Below iOS10: HLS (only clear), MP4, WVM
        if DRMSupport.fairplayOffline {
            if let source = sources.first(where: {$0.fileExt=="m3u8"}) {
                return source
            }
        } else {
            if let source = sources.first(where: {$0.fileExt=="m3u8" && $0.drmData==nil}) {
                return source
            }
        }
        
        if let source = sources.first(where: {$0.fileExt=="mp4"}) {
            return source
        }
        
        if DRMSupport.widevineClassic, let source = sources.first(where: {$0.fileExt=="wvm"}) {
            return source
        }
        
        return nil
    }

    /// Prepare a MediaEntry for download using AVAssetDownloadTask. 
    public func prepareForDownload(of mediaEntry: MediaEntry) -> (AVURLAsset, MediaSource)? {
        guard let source = getPreferredDownloadableMediaSource(for: mediaEntry) else { return nil }
        guard let url = source.contentUrl else { return nil }
        let avAsset = AVURLAsset(url: url)
        prepareForDownload(asset: avAsset, mediaSource: source)
        return (avAsset, source)
    }
    
    /// Notifies the SDK that downloading of an asset has finished.
    public func assetDownloadFinished(location: URL, mediaSource: MediaSource) {
        // FairPlay -- nothing to do
        
        // Widevine: TODO
    }
    
    private class NullStore: LocalDataStore {
        public func remove(key: String) throws {
            PKLog.error("LocalDataStore not set")
        }

        public func load(key: String) throws -> Data {
            PKLog.error("LocalDataStore not set")
            throw NSError.init(domain: "LocalAssetsManager", code: -1, userInfo: nil)
        }

        public func save(key: String, value: Data) throws {
            PKLog.error("LocalDataStore not set")
        }
        
        static let instance = NullStore()
    }
}

@objc public protocol LocalDataStore {
    func save(key: String, value: Data) throws
    func load(key: String) throws -> Data
    func remove(key: String) throws
}

/// Implementation of LocalDataStore that saves data to files in the Library directory.
public class DefaultLocalDataStore: NSObject, LocalDataStore {

    static let pkLocalDataStore = "pkLocalDataStore"
    let storageDirectory: URL

    public static func defaultDataStore() -> DefaultLocalDataStore? {
        return try? DefaultLocalDataStore(directory: .libraryDirectory)
    }
    
    private override init() {
        fatalError("Private initializer, use a factory or `init(directory:)`")
    }
    
    public init(directory: FileManager.SearchPathDirectory) throws {
        let baseDir = try FileManager.default.url(for: directory, in: .userDomainMask, appropriateFor: nil, create: false)
        self.storageDirectory = baseDir.appendingPathComponent(DefaultLocalDataStore.pkLocalDataStore, isDirectory: true)
        
        try FileManager.default.createDirectory(at: self.storageDirectory, withIntermediateDirectories: true, attributes: nil)
    }

    private func file(_ key: String) -> URL {
        return self.storageDirectory.appendingPathComponent(key)
    }

    public func save(key: String, value: Data) throws {
        try value.write(to: file(key), options: .atomic)
    }

    public func load(key: String) throws -> Data {
        return try Data.init(contentsOf: file(key), options: [])
    }

    public func remove(key: String) throws {
        try FileManager.default.removeItem(at: file(key))
    }
}

class LocalMediaSource: MediaSource {
    let storage: LocalDataStore

    init(storage: LocalDataStore, id: String, localContentUrl: URL) {
        self.storage = storage
        super.init(id, contentUrl: localContentUrl)
    }
}
