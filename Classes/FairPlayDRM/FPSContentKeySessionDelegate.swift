import AVFoundation
import SwiftyJSON

@available(iOS 10.3, *)
class FPSContentKeySessionDelegate: NSObject, AVContentKeySessionDelegate {
        
    var assetHelpersMap = [String: FPSLicenseHelper]()
    
    func contentKeySession(_ session: AVContentKeySession, didProvide keyRequest: AVContentKeyRequest) {
        try? handleContentKeyRequest(keyRequest: keyRequest)
    }
    
    func contentKeySession(_ session: AVContentKeySession, didProvide keyRequest: AVPersistableContentKeyRequest) {
        try? handleContentKeyRequest(keyRequest: keyRequest)
    }

    func contentKeySession(_ session: AVContentKeySession, didProvideRenewingContentKeyRequest keyRequest: AVContentKeyRequest) {
        try? handleContentKeyRequest(keyRequest: keyRequest)
    }
    
    func contentKeySession(_ session: AVContentKeySession,
                           didUpdatePersistableContentKey persistableContentKey: Data,
                           forContentKeyIdentifier keyIdentifier: Any) {
        
        #if DEBUG
        fatalError("Dual Expiry feature not implemented")
        #endif
    }

    func contentKeySession(_ session: AVContentKeySession, shouldRetry keyRequest: AVContentKeyRequest,
                           reason retryReason: AVContentKeyRequestRetryReason) -> Bool {
        
        var shouldRetry = false
        
        switch retryReason {
            /*
             Indicates that the content key request should be retried because the key response was not set soon enough either
             due the initial request/response was taking too long, or a lease was expiring in the meantime.
             */
        case AVContentKeyRequestRetryReason.timedOut:
            shouldRetry = true
            
            /*
             Indicates that the content key request should be retried because a key response with expired lease was set on the
             previous content key request.
             */
        case AVContentKeyRequestRetryReason.receivedResponseWithExpiredLease:
            shouldRetry = true
            
            /*
             Indicates that the content key request should be retried because an obsolete key response was set on the previous
             content key request.
             */
        case AVContentKeyRequestRetryReason.receivedObsoleteContentKey:
            shouldRetry = true
            
        default:
            break
        }
        
        return shouldRetry
    }
    
    // Informs the receiver a content key request has failed.
    func contentKeySession(_ session: AVContentKeySession, contentKeyRequest keyRequest: AVContentKeyRequest, didFailWithError err: Error) {
        // Add your code here to handle errors.
    }
    
    func assetHelper(_ keyIdentifier: Any?) -> FPSLicenseHelper? {
        guard let id = keyIdentifier as? String else { return nil }
        return assetHelpersMap[id]
    }
    
    func handleContentKeyRequest(keyRequest: AVContentKeyRequest) throws {
        
        guard let helper = assetHelper(keyRequest.identifier) else { return }
        
        if helper.forceDownload && !(keyRequest is AVPersistableContentKeyRequest) {
            // We want to download but we're given a non-download request
            keyRequest.respondByRequestingPersistableContentKeyRequest()
            return
        }
        
        helper.handleLicenseRequest(FPSContentKeyRequest(keyRequest)) { (error) in
            PKLog.debug("Done handleStreamingContentKeyRequest for \(helper.assetId)")
            self.assetHelpersMap.removeValue(forKey: helper.assetId)
        }
    }
}

@available(iOS 10.3, *)
class FPSContentKeyRequest: FPSLicenseRequest {
    let request: AVContentKeyRequest
    init(_ request: AVContentKeyRequest) {
        self.request = request
    }
    
    func getSPC(cert: Data, id: String, shouldPersist: Bool, callback: @escaping (Data?, Error?) -> Void) {
        let options = [AVContentKeyRequestProtocolVersionsKey: [1]]
        request.makeStreamingContentKeyRequestData(forApp: cert, contentIdentifier: id.data(using: .utf8)!, options: options, completionHandler: callback)
    }
    
    func processContentKeyResponse(_ keyResponse: Data) {
        request.processContentKeyResponse(AVContentKeyResponse(fairPlayStreamingKeyResponseData: keyResponse))
    }
    
    func processContentKeyResponseError(_ error: Error) {
        request.processContentKeyResponseError(error)
    }
    
    func persistableContentKey(fromKeyVendorResponse keyVendorResponse: Data, options: [String : Any]?) throws -> Data {
        if let request = self.request as? AVPersistableContentKeyRequest {
            return try request.persistableContentKey(fromKeyVendorResponse: keyVendorResponse, options: options)
        }
        fatalError("Invalid state")
    }
}

