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
        let storageUrl = try! FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        contentKeySession = AVContentKeySession(keySystem: .fairPlayStreaming, storageDirectoryAt: storageUrl)
        contentKeyDelegate = FPSContentKeySessionDelegate()
        
        contentKeySession.setDelegate(contentKeyDelegate, queue: contentKeyDelegateQueue)
    }
    
    func installOfflineLicense(for location: URL, mediaSource: PKMediaSource, dataStore: LocalDataStore, callback: @escaping (Error?) -> Void) throws {
        
        let drmParams = try mediaSource.fairPlayParams()

        guard let id = FPSUtils.extractAssetId(at: location) else {return}
        let skdUrl = "skd://" + id
        let helper = FPSLicenseHelper(assetId: id, params: drmParams, dataStore: dataStore, forceDownload: true)
        helper?.doneCallback = callback
        contentKeyDelegate.assetHelpersMap[skdUrl] = helper
        
        contentKeySession.processContentKeyRequest(withIdentifier: skdUrl, initializationData: nil, options: nil)
    }
}
#endif
