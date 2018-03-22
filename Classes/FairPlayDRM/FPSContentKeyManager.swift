import AVFoundation

@available(iOS 10.3, *)
class FPSContentKeyManager {
    
    // MARK: Types.
    
    /// The singleton for `ContentKeyManager`.
    static let shared: FPSContentKeyManager = FPSContentKeyManager()
    
    // MARK: Properties.
    
    /// The instance of `AVContentKeySession` that is used for managing and preloading content keys.
    let contentKeySession: AVContentKeySession
    
    /**
     The instance of `ContentKeyDelegate` which conforms to `AVContentKeySessionDelegate` and is used to respond to content key requests from
     the `AVContentKeySession`
     */
    let contentKeyDelegate: FPSContentKeySessionDelegate
    
    /// The DispatchQueue to use for delegate callbacks.
    let contentKeyDelegateQueue = DispatchQueue(label: "com.example.apple-samplecode.HLSCatalog.ContentKeyDelegateQueue")
    
    // MARK: Initialization.
    
    private init() {
        let storageUrl = try! FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        contentKeySession = AVContentKeySession(keySystem: .fairPlayStreaming, storageDirectoryAt: storageUrl)
        contentKeyDelegate = FPSContentKeySessionDelegate()
        
        contentKeySession.setDelegate(contentKeyDelegate, queue: contentKeyDelegateQueue)
    }
    
    func requestPersistableContentKeys(for mediaSource: PKMediaSource, with assetId: String, dataStore: LocalDataStore) {
        
        guard let drmParams = mediaSource.drmData?.first as? FairPlayDRMParams else { fatalError("Not a FairPlay source") }

        let skdURL = "skd://" + assetId
        
        do {
            let helper = try FPSLicenseHelper(assetId: assetId, params: drmParams, dataStore: dataStore, forceDownload: true)
            contentKeyDelegate.assetHelpersMap[skdURL] = helper
        } catch {
            return /// TODOerr
        }
        
        contentKeySession.processContentKeyRequest(withIdentifier: skdURL, initializationData: nil, options: nil)
    }
}
