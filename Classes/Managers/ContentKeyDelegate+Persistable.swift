/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This extension on `ContentKeyDelegate` implements the `AVContentKeySessionDelegate` protocol methods related to persistable content keys.
 */

import AVFoundation

extension ContentKeyDelegate {
    
    /*
     Provides the receiver with a new content key request that allows key persistence.
     Will be invoked by an AVContentKeyRequest as the result of a call to
     -respondByRequestingPersistableContentKeyRequest.
     */
    func contentKeySession(_ session: AVContentKeySession, didProvide keyRequest: AVPersistableContentKeyRequest) {
        try? handlePersistableContentKeyRequest(keyRequest: keyRequest)
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
            deletePeristableContentKey(withContentKeyIdentifier: assetIDString)
            
            try writePersistableContentKey(contentKey: persistableContentKey, withContentKeyIdentifier: assetIDString)
        } catch {
            print("Failed to write updated persistable content key to disk: \(error.localizedDescription)")
        }
    }
    
    func getAssetId(_ keyRequest: AVContentKeyRequest) throws -> String {
        guard let keyId = keyRequest.identifier as? String,
            let url = URL(string: keyId), let assetId = url.host else { throw internalError.invalidAssetKeyId }
        return assetId
    }
    
    func fetchAndSaveLicense(with keyRequest: AVPersistableContentKeyRequest, forceDownload: Bool = false) throws {
        let assetId = try getAssetId(keyRequest)
        let keyLocation = urlForPersistableContentKey(withContentKeyIdentifier: assetId)
        
        if !forceDownload && FileManager.default.fileExists(atPath: keyLocation.path) {
            if let storedKey = try? Data.init(contentsOf: keyLocation) {
                // Create an AVContentKeyResponse from the persistent key data to use for requesting a key for
                // decrypting content.
                let keyResponse = AVContentKeyResponse(fairPlayStreamingKeyResponseData: storedKey)
                
                // Provide the content key response to make protected content available for processing.
                keyRequest.processContentKeyResponse(keyResponse)
            }
            return
        }

        do {
            let applicationCertificate = try requestApplicationCertificate(assetId: assetId)
            
            let completionHandler = { [weak self] (spcData: Data?, error: Error?) in
                guard let strongSelf = self else { return }
                if let error = error {
                    keyRequest.processContentKeyResponseError(error)
                    
                    strongSelf.pendingPersistableContentKeyIdentifiers.remove(assetId)
                    return
                }
                
                guard let spcData = spcData else { return }
                
                do {
                    // Send SPC to Key Server and obtain CKC
                    let ckcData = try strongSelf.requestContentKeyFromKeySecurityModule(spcData: spcData, assetID: assetId)
                    
                    let persistentKey = try keyRequest.persistableContentKey(fromKeyVendorResponse: ckcData, options: nil)
                    
                    try strongSelf.writePersistableContentKey(contentKey: persistentKey, withContentKeyIdentifier: assetId)
                    
                    /*
                     AVContentKeyResponse is used to represent the data returned from the key server when requesting a key for
                     decrypting content.
                     */
                    let keyResponse = AVContentKeyResponse(fairPlayStreamingKeyResponseData: persistentKey)
                    
                    /*
                     Provide the content key response to make protected content available for processing.
                     */
                    keyRequest.processContentKeyResponse(keyResponse)
                    
                    strongSelf.pendingPersistableContentKeyIdentifiers.remove(assetId)
                } catch {
                    keyRequest.processContentKeyResponseError(error)
                    
                    strongSelf.pendingPersistableContentKeyIdentifiers.remove(assetId)
                }
            }
            
            keyRequest.makeStreamingContentKeyRequestData(forApp: applicationCertificate,
                                                          contentIdentifier: assetId.data(using: .utf8)!,
                                                          options: [AVContentKeyRequestProtocolVersionsKey: [1]],
                                                          completionHandler: completionHandler)
        } catch {
            keyRequest.processContentKeyResponseError(error)
        }

    }
    
    // MARK: API.
    
    /// Handles responding to an `AVPersistableContentKeyRequest` by determining if a key is already available for use on disk.
    /// If no key is available on disk, a persistable key is requested from the server and securely written to disk for use in the future.
    /// In both cases, the resulting content key is used as a response for the `AVPersistableContentKeyRequest`.
    ///
    /// - Parameter keyRequest: The `AVPersistableContentKeyRequest` to respond to.
    func handlePersistableContentKeyRequest(keyRequest: AVPersistableContentKeyRequest) throws {
        
        let assetId = try getAssetId(keyRequest)
        if pendingPersistableContentKeyIdentifiers.contains(assetId) {
            // download only, don't even check disk
            return try fetchAndSaveLicense(with: keyRequest, forceDownload: true)
        }
        
        // Playback mode: try to use a local license. If not available, fetch and store a new license, then try to use it.
        
        // "Worst" case: playback requested with no stored key. Try to get a response from the server.
        // TODO: unify with download mode?
        try fetchAndSaveLicense(with: keyRequest)
        
    }
    
    /// Deletes all the persistable content keys on disk for a specific `Asset`.
    ///
    /// - Parameter asset: The `Asset` value to remove keys for.
    func deleteAllPeristableContentKeys(forAsset asset: Asset) {
        if let contentKeyIdentifier = asset.id {
            deletePeristableContentKey(withContentKeyIdentifier: contentKeyIdentifier)
        }
    }
    
    /// Deletes a persistable key for a given content key identifier.
    ///
    /// - Parameter contentKeyIdentifier: The host value of an `AVPersistableContentKeyRequest`. (i.e. "tweleve" in "skd://tweleve").
    func deletePeristableContentKey(withContentKeyIdentifier contentKeyIdentifier: String) {
        
        guard persistableContentKeyExistsOnDisk(withContentKeyIdentifier: contentKeyIdentifier) else { return }
        
        let contentKeyURL = urlForPersistableContentKey(withContentKeyIdentifier: contentKeyIdentifier)
        
        do {
            try FileManager.default.removeItem(at: contentKeyURL)
            
            UserDefaults.standard.removeObject(forKey: "\(contentKeyIdentifier)-Key")
        } catch {
            print("An error occured removing the persisted content key: \(error)")
        }
    }
    
    /// Returns whether or not a persistable content key exists on disk for a given content key identifier.
    ///
    /// - Parameter contentKeyIdentifier: The host value of an `AVPersistableContentKeyRequest`. (i.e. "tweleve" in "skd://tweleve").
    /// - Returns: `true` if the key exists on disk, `false` otherwise.
    func persistableContentKeyExistsOnDisk(withContentKeyIdentifier contentKeyIdentifier: String) -> Bool {
        let contentKeyURL = urlForPersistableContentKey(withContentKeyIdentifier: contentKeyIdentifier)
        
        return FileManager.default.fileExists(atPath: contentKeyURL.path)
    }
    
    // MARK: Private APIs
    
    /// Returns the `URL` for persisting or retrieving a persistable content key.
    ///
    /// - Parameter contentKeyIdentifier: The host value of an `AVPersistableContentKeyRequest`. (i.e. "tweleve" in "skd://tweleve").
    /// - Returns: The fully resolved file URL.
    func urlForPersistableContentKey(withContentKeyIdentifier contentKeyIdentifier: String) -> URL {
        return contentKeyDirectory.appendingPathComponent("\(contentKeyIdentifier).fpskey") // ("\(contentKeyIdentifier)-Key")
    }
    
    /// Writes out a persistable content key to disk.
    ///
    /// - Parameters:
    ///   - contentKey: The data representation of the persistable content key.
    ///   - contentKeyIdentifier: The host value of an `AVPersistableContentKeyRequest`. (i.e. "tweleve" in "skd://tweleve").
    /// - Throws: If an error occurs during the file write process.
    func writePersistableContentKey(contentKey: Data, withContentKeyIdentifier contentKeyIdentifier: String) throws {
        
        let fileURL = urlForPersistableContentKey(withContentKeyIdentifier: contentKeyIdentifier)
        
        try contentKey.write(to: fileURL, options: Data.WritingOptions.atomicWrite)
    }
    
}

extension Notification.Name {
    
    /**
     The notification that is posted when all the content keys for a given asset have been saved to disk.
     */
    static let ContentKeyDelegateDidSaveAllPersistableContentKey = Notification.Name.init("ContentKeyDelegateDidSaveAllPersistableContentKey")
}
