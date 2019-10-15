// ===================================================================================================
// Copyright (C) 2018 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import AVFoundation

#if os(iOS)
@available(iOS 10.3, *)
class FPSContentKeyManager {
    
    static let shared: FPSContentKeyManager = FPSContentKeyManager()
    
    /// The instance of `AVContentKeySession` that is used for managing and preloading content keys.
    let contentKeySession: AVContentKeySession
    
    let contentKeyDelegate: FPSContentKeySessionDelegate
    
    /// The DispatchQueue to use for delegate callbacks.
    let contentKeyDelegateQueue = DispatchQueue(label: "com.kaltura.playkit.contentKeyDelegateQueue")
    
    // MARK: Initialization.
    
    private init() {
        if #available(iOS 11.0, *) {
            contentKeySession = AVContentKeySession(keySystem: .fairPlayStreaming)
        } else {
            // iOS 10.3
            let storageUrl = try! FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("pkLegacyExpiredContentKeySessionReports", isDirectory: true)
            try? FileManager.default.createDirectory(at: storageUrl, withIntermediateDirectories: true, attributes: nil)
            contentKeySession = AVContentKeySession(keySystem: .fairPlayStreaming, storageDirectoryAt: storageUrl)
        }
        contentKeyDelegate = FPSContentKeySessionDelegate()
        
        contentKeySession.setDelegate(contentKeyDelegate, queue: contentKeyDelegateQueue)
    }
    
    func installOfflineLicense(for location: URL, mediaSource: PKMediaSource, dataStore: LocalDataStore, callback: @escaping (Error?) -> Void) throws {
        
        let drmParams = try mediaSource.fairPlayParams()

        guard let id = FPSUtils.extractAssetId(at: location) else {
            PKLog.error("Asset at \(location.absoluteString) is missing the asset id")
            throw FPSError.missingAssetId(location)
        }
        
        let skdUrl = "skd://" + id
        let helper = FPSLicenseHelper(assetId: id, params: drmParams, dataStore: dataStore, forceDownload: true)
        helper?.doneCallback = callback
        contentKeyDelegate.assetHelpersMap[skdUrl] = helper
        
        contentKeySession.processContentKeyRequest(withIdentifier: skdUrl, initializationData: nil, options: nil)
    }
}
#endif
