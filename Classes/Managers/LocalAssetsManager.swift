//
//  LocalAssetsManager.swift
//  Pods
//
//  Created by Noam Tamim on 15/12/2016.
//
//

import Foundation
import AVFoundation

// FairPlay is not available in simulators and is only downloadable in iOS10 and up.
fileprivate let canDownloadFairPlay: Bool = {
    if TARGET_OS_SIMULATOR==0, #available(iOS 10, *) {
        return true
    } else {
        return false
    }
}()

// Widevine is optional (and not available in simulators)
fileprivate let canDownloadWidevineClassic: Bool = TARGET_OS_SIMULATOR==0 
    && NSClassFromString("WidevineClassicAssetHandler") != nil


public class LocalAssetsManager: NSObject {
    let storage: LocalDrmStorage
    var delegates = Set<AssetLoaderDelegate>()
    

    public init(storage: LocalDrmStorage) {
        self.storage = storage
    }

    public func prepareForDownload(asset: AVURLAsset, mediaSource: MediaSource) {
        
        // This function is a noop (not an error) if no DRM data or DRM is not FairPlay.
        guard let drmData = mediaSource.drmData?.first as? FairPlayDRMData else {return}


        PKLog.debug("Preparing asset for download; asset.url:", asset.url)
        
        guard #available(iOS 10, *), canDownloadFairPlay else {
            PKLog.error("Downloading FairPlay content is not supported on device")
            return
        }

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
    
    public func getPreferredDownloadableMediaSource(for mediaEntry: MediaEntry) -> MediaSource? {

        guard let sources = mediaEntry.sources else {return nil}
        
        // On iOS 10 and up: HLS (clear or FP), MP4, WVM
        // Below iOS10: HLS (only clear), MP4, WVM
        if canDownloadFairPlay {
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
        
        if canDownloadWidevineClassic, let source = sources.first(where: {$0.fileExt=="wvm"}) {
            return source
        }
            
        return nil
    }

    public func prepareForDownload(of mediaEntry: MediaEntry) -> (AVURLAsset, MediaSource)? {
        guard let source = getPreferredDownloadableMediaSource(for: mediaEntry) else { return nil }
        guard let url = source.contentUrl else { return nil }
        let avAsset = AVURLAsset(url: url)
        prepareForDownload(asset: avAsset, mediaSource: source)
        return (avAsset, source)
    }
    
    public func registerDownloadedAsset(location: URL, mediaSource: MediaSource) {
        // FairPlay -- nothing to do
        
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
