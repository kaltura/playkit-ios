import AVFoundation

@available(iOS 10.3, *)
extension FPSContentKeySessionDelegate {
    
    /*
     Provides the receiver with a new content key request that allows key persistence.
     Will be invoked by an AVContentKeyRequest as the result of a call to
     -respondByRequestingPersistableContentKeyRequest.
     */
    func contentKeySession(_ session: AVContentKeySession, didProvide keyRequest: AVPersistableContentKeyRequest) {
        try? handleContentKeyRequest(keyRequest: keyRequest)
    }
    
    /*
     Provides the receiver with an updated persistable content key for a particular key request.
     If the content key session provides an updated persistable content key data, the previous
     key data is no longer valid and cannot be used to answer future loading requests.
     */
    func contentKeySession(_ session: AVContentKeySession,
                           didUpdatePersistableContentKey persistableContentKey: Data,
                           forContentKeyIdentifier keyIdentifier: Any) {
        
        /*
         The key ID is the URI from the EXT-X-KEY tag in the playlist (e.g. "skd://key65") and the
         asset ID in this case is "key65".
         */
        guard let contentKeyIdentifierString = keyIdentifier as? String,
            let contentKeyIdentifierURL = URL(string: contentKeyIdentifierString),
            let assetIDString = contentKeyIdentifierURL.host
            else {
                print("Failed to retrieve the assetID from the keyRequest!")
                return
        }
        
        do {
            FairPlayUtils.deletePeristableContentKey(withContentKeyIdentifier: assetIDString)
            
            try FairPlayUtils.writePersistableContentKey(contentKey: persistableContentKey, withContentKeyIdentifier: assetIDString)
        } catch {
            print("Failed to write updated persistable content key to disk: \(error.localizedDescription)")
        }
    }
}
