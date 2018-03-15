import AVFoundation
import SwiftyJSON

@available(iOS 10.3, *)
class FPSContentKeySessionDelegate: NSObject, AVContentKeySessionDelegate {
        
    var assetHelpersMap = [String: FairPlayLicenseHelper]()
    
    func contentKeySession(_ session: AVContentKeySession, didProvide keyRequest: AVContentKeyRequest) {
        try? handleContentKeyRequest(keyRequest: keyRequest) // TODO
    }
    
    func contentKeySession(_ session: AVContentKeySession, didProvideRenewingContentKeyRequest keyRequest: AVContentKeyRequest) {
        try? handleContentKeyRequest(keyRequest: keyRequest) // TODO
    }
    
    /*
     Provides the receiver a content key request that should be retried because a previous content key request failed.
     Will be invoked by an AVContentKeySession when a content key request should be retried. The reason for failure of
     previous content key request is specified. The receiver can decide if it wants to request AVContentKeySession to
     retry this key request based on the reason. If the receiver returns YES, AVContentKeySession would restart the
     key request process. If the receiver returns NO or if it does not implement this delegate method, the content key
     request would fail and AVContentKeySession would let the receiver know through
     -contentKeySession:contentKeyRequest:didFailWithError:.
     */
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
    
    func assetHelper(_ keyIdentifier: Any?) -> FairPlayLicenseHelper? {
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
        
        try helper.fetchLicense(with: keyRequest) { 
            // TODO?
            PKLog.debug("Done handleStreamingContentKeyRequest for \(helper.assetId)")
            self.assetHelpersMap.removeValue(forKey: helper.assetId)
        }
    }
}
