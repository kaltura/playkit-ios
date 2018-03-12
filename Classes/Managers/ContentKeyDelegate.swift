import AVFoundation
import SwiftyJSON

@available(iOS 10.3, *)
class ContentKeyDelegate: NSObject, AVContentKeySessionDelegate {
    
    // MARK: Types
    
    enum error: Error {
        case missingApplicationCertificate
        case noCKCReturnedByKSM
    }
    
    enum internalError: Error {
        case unknownAssetKeyId
        case unknownAssetMode
        case invalidAssetKeyId
    }
    
    enum Mode: String {
        case localPlay
        case download
        case remotePlay
    }
    
    // MARK: Properties
    
    /// The directory that is used to save persistable content keys.
    lazy var contentKeyDirectory = try! DefaultLocalDataStore.storageDir()
//    lazy var contentKeyDirectory: URL = {
//        guard let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else { fatalError("Unable to determine library URL") }
//        
//        let documentURL = URL(fileURLWithPath: documentPath)
//        
//        let contentKeyDirectory = documentURL.appendingPathComponent(".keys", isDirectory: true)
//        
//        if !FileManager.default.fileExists(atPath: contentKeyDirectory.path, isDirectory: nil) {
//            do {
//                try FileManager.default.createDirectory(at: contentKeyDirectory,
//                                                    withIntermediateDirectories: false,
//                                                    attributes: nil)
//            } catch {
//                fatalError("Unable to create directory for content keys at path: \(contentKeyDirectory.path)")
//            }
//        }
//        
//        return contentKeyDirectory
//    }()
    
    /// A set containing the currently pending content key identifiers associated with persistable content key requests that have not been completed.
    var pendingPersistableContentKeyIdentifiers = Set<String>()
    
    var contentKeyToDRMParamsMap = [String: FairPlayDRMParams]()
    
//    var assetModeMap = [String: Mode]()
    
    func requestApplicationCertificate(assetId: String) throws -> Data {
        
        if let drmParams = contentKeyToDRMParamsMap[assetId], let cert = drmParams.fpsCertificate {
            return cert
        } else {
            throw error.missingApplicationCertificate
        }
    }
    
    func parseServerResponse(data: Data?) throws -> Data {
        guard let data = data else {
            throw FairPlayError.emptyServerResponse
        }
        
        let json = JSON(data: data, options: [])
        
        guard let b64CKC = json["ckc"].string else {
            throw FairPlayError.noCKCInResponse
        }
        
        guard let ckc = Data(base64Encoded: b64CKC) else {
            throw FairPlayError.malformedCKCInResponse
        }
        
        if ckc.count == 0 {
            throw FairPlayError.malformedCKCInResponse
        }
        
        PKLog.debug("Got valid CKC")
        
        return ckc
    }
    

    func performCKCRequest(_ spcData: Data, licenseUrl: URL) -> Data {
                
        var request = URLRequest(url: licenseUrl)
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.httpBody = spcData.base64EncodedData()
        request.httpMethod = "POST"
        
        PKLog.debug("Sending SPC to server");
        let startTime: Double = Date.timeIntervalSinceReferenceDate
        var response: URLResponse?
        let data = try! NSURLConnection.sendSynchronousRequest(request, returning: &response)
        let ckc = try! self.parseServerResponse(data: data)
        return ckc
        
//        let dataTask = URLSession.shared.dataTask(with: request, completionHandler: {(data: Data?, response: URLResponse?, error: Error?) -> Void in
//            do {
//                let endTime: Double = Date.timeIntervalSinceReferenceDate
//                PKLog.debug("Got response in \(endTime-startTime) sec")
//                let ckc = try self.parseServerResponse(data: data, error: error)
//                callback(ckc,nil)
//            } catch let e {
//                callback(nil,e)
//            }
//        })
//        dataTask.resume()
    }

    func requestContentKeyFromKeySecurityModule(spcData: Data, assetID: String) throws -> Data {
        
        // MARK: ADAPT - You must implement this method to request a CKC from your KSM.
        
        guard let drmParams = contentKeyToDRMParamsMap[assetID], let licenseUrl = drmParams.licenseUri else {
            // TODO error
            return Data()
        }
        
        return performCKCRequest(spcData, licenseUrl: licenseUrl)
        
        
        1/Int(0)
        let ckcData: Data? = nil
        
        guard ckcData != nil else {
            throw error.noCKCReturnedByKSM
        }
        
        return ckcData!
    }
    
    /// Preloads all the content keys associated with an Asset for persisting on disk.
    ///
    /// - Parameter asset: The `Asset` to preload keys for.
    func requestPersistableContentKeys(for assetId: String, mediaSource: PKMediaSource) {
//        guard let contentKeyIdentifierURL = URL(string: assetId), let assetIDString = contentKeyIdentifierURL.host else { return }
            
        pendingPersistableContentKeyIdentifiers.insert(assetId)
        contentKeyToDRMParamsMap[assetId] = mediaSource.drmData?.first as! FairPlayDRMParams
            
        let skdURL = "skd://" + assetId
            ContentKeyManager.shared.contentKeySession.processContentKeyRequest(withIdentifier: skdURL, initializationData: nil, options: nil)
//        }
    }
    
    /// Returns whether or not a content key should be persistable on disk.
    ///
    /// - Parameter identifier: The asset ID associated with the content key request.
    /// - Returns: `true` if the content key request should be persistable, `false` otherwise.
    func shouldRequestPersistableContentKey(withIdentifier identifier: String) -> Bool {
        return pendingPersistableContentKeyIdentifiers.contains(identifier)
    }
    
    // MARK: AVContentKeySessionDelegate Methods
    
    /*
     The following delegate callback gets called when the client initiates a key request or AVFoundation
     determines that the content is encrypted based on the playlist the client provided when it requests playback.
     */
    func contentKeySession(_ session: AVContentKeySession, didProvide keyRequest: AVContentKeyRequest) {
        if let pckr = keyRequest as? AVPersistableContentKeyRequest {
            try? handlePersistableContentKeyRequest(keyRequest: pckr)   // TODO
        } else {
            try? handleStreamingContentKeyRequest(keyRequest: keyRequest) // TODO
        }
    }
    
    /*
     Provides the receiver with a new content key request representing a renewal of an existing content key.
     Will be invoked by an AVContentKeySession as the result of a call to -renewExpiringResponseDataForContentKeyRequest:.
     */
    func contentKeySession(_ session: AVContentKeySession, didProvideRenewingContentKeyRequest keyRequest: AVContentKeyRequest) {
        try? handleStreamingContentKeyRequest(keyRequest: keyRequest) // TODO
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
    
    // MARK: API
    
    func handleStreamingContentKeyRequest(keyRequest: AVContentKeyRequest) throws {
        let assetIDString = try getAssetId(keyRequest)
        
        #if os(iOS)
            /*
             When you receive an AVContentKeyRequest via -contentKeySession:didProvideContentKeyRequest:
             and you want the resulting key response to produce a key that can persist across multiple
             playback sessions, you must invoke -respondByRequestingPersistableContentKeyRequest on that
             AVContentKeyRequest in order to signal that you want to process an AVPersistableContentKeyRequest
             instead. If the underlying protocol supports persistable content keys, in response your
             delegate will receive an AVPersistableContentKeyRequest via -contentKeySession:didProvidePersistableContentKeyRequest:.
             */
            if shouldRequestPersistableContentKey(withIdentifier: assetIDString) ||
                persistableContentKeyExistsOnDisk(withContentKeyIdentifier: assetIDString) {
                
                //Request a Persistable Key Request
                keyRequest.respondByRequestingPersistableContentKeyRequest()
                
                return
            }
        #endif
        
        do {
            let applicationCertificate = try requestApplicationCertificate(assetId: assetIDString)
            
            let completionHandler = { [weak self] (spcData: Data?, error: Error?) in
                guard let strongSelf = self else { return }
                if let error = error {
                    keyRequest.processContentKeyResponseError(error)
                    return
                }
                
                guard let spcData = spcData else { return }
                
                do {
                    // Send SPC to Key Server and obtain CKC
                    let ckcData = try strongSelf.requestContentKeyFromKeySecurityModule(spcData: spcData, assetID: assetIDString)
                    
                    /*
                     AVContentKeyResponse is used to represent the data returned from the key server when requesting a key for
                     decrypting content.
                     */
                    let keyResponse = AVContentKeyResponse(fairPlayStreamingKeyResponseData: ckcData)
                    
                    /*
                     Provide the content key response to make protected content available for processing.
                     */
                    keyRequest.processContentKeyResponse(keyResponse)
                } catch {
                    keyRequest.processContentKeyResponseError(error)
                }
            }
            
            keyRequest.makeStreamingContentKeyRequestData(forApp: applicationCertificate,
                                                          contentIdentifier: assetIDString.data(using: .utf8)!,
                                                          options: [AVContentKeyRequestProtocolVersionsKey: [1]],
                                                          completionHandler: completionHandler)
        } catch {
            keyRequest.processContentKeyResponseError(error)
        }
    }
}
