import AVFoundation

fileprivate let skdUrlPattern = try? NSRegularExpression(pattern: "URI=\"skd://([\\w-]+)\"", options: [])

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
    
    func installFairPlayOfflineLicense(for location: URL, mediaSource: PKMediaSource, dataStore: LocalDataStore, done: @escaping (Error?)->Void) {
        guard let drmParams = mediaSource.drmData?.first as? FairPlayDRMParams else { fatalError("Not a FairPlay source") }
        guard let params = FPSParams(drmParams) else { fatalError("Missing DRM parameters") }

        // Master should have the following line:
        // #EXT-X-SESSION-KEY:METHOD=SAMPLE-AES,URI="skd://entry-1_x14v3p06",KEYFORMAT="com.apple.streamingkeydelivery",KEYFORMATVERSIONS="1"
        // The following code looks for the first line with "EXT-X-SESSION-KEY" tag.
        guard let re = skdUrlPattern else { fatalError() }
        guard let master = try? String(contentsOf: location) else { PKLog.error("Can't read master playlist", location); return }
        let lines = master.components(separatedBy: .newlines)
        var assetId: String? = nil
        for line in lines {
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("#EXT-X-SESSION-KEY") {
                guard let match = re.firstMatch(in: line, options: [], range: NSMakeRange(0, line.count)) else { continue }
                if match.numberOfRanges < 2 { continue }
                let assetIdRange = match.range(at: 1)
                let start = line.index(line.startIndex, offsetBy: assetIdRange.location)
                let end = line.index(line.startIndex, offsetBy: assetIdRange.location + assetIdRange.length - 1)
                assetId = String(line[start...end])
                break
            }
        }

        guard let id = assetId else { return }
        let skdUrl = "skd://" + id
        let helper = FPSLicenseHelper(assetId: id, params: params, dataStore: dataStore, forceDownload: true)
        helper?.done = done
        contentKeyDelegate.assetHelpersMap[skdUrl] = helper
        
        contentKeySession.processContentKeyRequest(withIdentifier: skdUrl, initializationData: nil, options: nil)

        
    }
}
