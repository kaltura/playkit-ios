
import Foundation
import AVFoundation
import SwiftyJSON

enum FairPlayError: Error {
    case emptyServerResponse
    case malformedServerResponse
    case noCKCInResponse
    case malformedCKCInResponse
    case noLicenseURL
    case noAppCertificate
}


class FPSLicenseHelper {
    
    let assetId: String
    
    let appCertificate: Data?
    let licenseUrl: URL?
    
    let forceDownload: Bool
    let shouldPersist: Bool

    init(assetId: String, params: FairPlayDRMParams, shouldPersist: Bool, forceDownload: Bool = false) throws {
        self.assetId = assetId
        
        guard let cert = params.fpsCertificate else {throw FairPlayError.noAppCertificate}
        guard let url = params.licenseUri else { throw FairPlayError.noLicenseURL }
        
        self.appCertificate = cert
        self.licenseUrl = url
        
        self.forceDownload = forceDownload
        self.shouldPersist = shouldPersist
    }
    
    init(assetId: String) {
        self.assetId = assetId
        self.forceDownload = false
        self.appCertificate = nil
        self.licenseUrl = nil
        self.shouldPersist = true
   }
    
    @available(iOS 10.3, *)
    static func getAssetId(_ keyRequest: AVContentKeyRequest) throws -> String {
        return try getAssetId(keyIdentifier: keyRequest.identifier)
    }
    
    static func getAssetId(keyIdentifier: Any?) throws -> String {
        guard let keyId = keyIdentifier as? String,
            let url = URL(string: keyId), let assetId = url.host else { throw internalError.invalidAssetKeyId }
        return assetId
    }
    
    func performCKCRequest(_ spcData: Data) throws -> Data {
        
        guard let url = self.licenseUrl else { throw FairPlayError.noLicenseURL }
        
        var request = URLRequest(url: url)
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.httpBody = spcData.base64EncodedData()
        request.httpMethod = "POST"
        
        PKLog.debug("Sending SPC to server")
        var response: URLResponse?
        let data = try NSURLConnection.sendSynchronousRequest(request, returning: &response)
        let ckc = try self.parseServerResponse(data: data)
        return ckc
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

    func fetchLicense(resourceLoadingRequest: AVAssetResourceLoadingRequest, usePersistence: Bool, done: (Error?) -> Void) throws {
        // Check if we have an existing key on disk for this asset.
        let keyLocation = FairPlayUtils.urlForPersistableContentKey(withContentKeyIdentifier: assetId)
        
        if !forceDownload && FileManager.default.fileExists(atPath: keyLocation.path) {
            guard let dataRequest = resourceLoadingRequest.dataRequest else {
                PKLog.error("Error loading contents of content key file.")
                let error = NSError(domain: FPSAssetLoaderDelegate.errorDomain, code: -2, userInfo: nil)
                resourceLoadingRequest.finishLoading(with: error)
                done(error)
                return
            }
            
            if let storedKey = try? Data.init(contentsOf: keyLocation) {
                
                // Pass the persistedContentKeyData into the dataRequest to complete the content key request.
                dataRequest.respond(with: storedKey)
                resourceLoadingRequest.finishLoading()
                done(nil)
            }
            return
        }

        guard let appCert = self.appCertificate else { throw FairPlayError.noAppCertificate }
        
        var resourceLoadingRequestOptions: [String: AnyObject]? = nil
        
        if #available(iOS 10.0, *), usePersistence {
            resourceLoadingRequestOptions = [AVAssetResourceLoadingRequestStreamingContentKeyRequestRequiresPersistentKey: true as AnyObject]
        }
        
        let spcData: Data!
        
        do {
            /*
             To obtain the Server Playback Context (SPC), we call
             AVAssetResourceLoadingRequest.streamingContentKeyRequestData(forApp:contentIdentifier:options:)
             using the information we obtained earlier.
             */
            spcData = try resourceLoadingRequest.streamingContentKeyRequestData(forApp: appCert, contentIdentifier: assetId.data(using: .utf8)!, options: resourceLoadingRequestOptions)
            PKLog.debug("Got spcData with", spcData.count, "bytes")
        } catch let error as NSError {
            PKLog.error("Error obtaining key request data: \(error.domain) reason: \(String(describing: error.localizedFailureReason))")
            resourceLoadingRequest.finishLoading(with: error)
            done(error)
            return
        }
        
        do {
            let ckcData = try performCKCRequest(spcData)
            self.handleCKCData(resourceLoadingRequest, ckcData: ckcData, done: done)
        } catch {
            PKLog.error("Error occured while loading FairPlay license:", error)
        }
    }

    func handleCKCData(_ resourceLoadingRequest: AVAssetResourceLoadingRequest, ckcData: Data, done: (Error?) -> Void) {
        
        // Check if this reuqest is the result of a potential AVAssetDownloadTask.
        if #available(iOS 10.0, *), shouldPersist {
            /* Since this request is the result of an AVAssetDownloadTask, we should get the secure persistent content key.
             Obtain a persistable content key from a context.
             
             The data returned from this method may be used to immediately satisfy an
             AVAssetResourceLoadingDataRequest, as well as any subsequent requests for the same key url.
             
             The value of AVAssetResourceLoadingContentInformationRequest.contentType must be set to AVStreamingKeyDeliveryPersistentContentKeyType when responding with data created with this method.
             */
            do {
                let persistentContentKeyData = try resourceLoadingRequest.persistentContentKey(fromKeyVendorResponse: ckcData, options: nil)
                
                // Save the persistentContentKeyData onto disk for use in the future.
                PKLog.debug("Saving persistentContentKeyData")
                try FairPlayUtils.writePersistableContentKey(contentKey: persistentContentKeyData, withContentKeyIdentifier: assetId)
                
                guard let dataRequest = resourceLoadingRequest.dataRequest else {
                    PKLog.error("no data is being requested in loadingRequest")
                    let error = NSError(domain: FPSAssetLoaderDelegate.errorDomain, code: -6, userInfo: nil)
                    resourceLoadingRequest.finishLoading(with: error)
                    done(error)
                    return
                }
                // Provide data to the loading request.
                dataRequest.respond(with: persistentContentKeyData)
                resourceLoadingRequest.finishLoading()  // Treat the processing of the request as complete.
                done(nil)
            } catch {
                PKLog.error("Error creating persistent content key: \(error)")
                resourceLoadingRequest.finishLoading(with: error)
                done(error)
                return
            }
        } else {
            
            guard let dataRequest = resourceLoadingRequest.dataRequest else {
                PKLog.error("no data is being requested in loadingRequest")
                let error = NSError(domain: FPSAssetLoaderDelegate.errorDomain, code: -6, userInfo: nil)
                resourceLoadingRequest.finishLoading(with: error)
                done(error)
                return
            }
            
            // Provide data to the loading request.
            dataRequest.respond(with: ckcData)
            resourceLoadingRequest.finishLoading()  // Treat the processing of the request as complete.
            done(nil)
        }
    }
    
    @available(iOS 10.3, *)
    func fetchLicense(contentKeyRequest: AVContentKeyRequest, done: @escaping () -> Void) throws {
        let assetId = self.assetId
        let keyLocation = FairPlayUtils.urlForPersistableContentKey(withContentKeyIdentifier: assetId)
        
        if !forceDownload && FileManager.default.fileExists(atPath: keyLocation.path) {
            if let storedKey = try? Data.init(contentsOf: keyLocation) {
                // Create an AVContentKeyResponse from the persistent key data to use for requesting a key for
                // decrypting content.
                let keyResponse = AVContentKeyResponse(fairPlayStreamingKeyResponseData: storedKey)
                
                // Provide the content key response to make protected content available for processing.
                contentKeyRequest.processContentKeyResponse(keyResponse)
            }
            return
        }
        
        guard let appCert = self.appCertificate else { throw FairPlayError.noAppCertificate }
        
        contentKeyRequest.makeStreamingContentKeyRequestData(forApp: appCert, 
                                                      contentIdentifier: assetId.data(using: .utf8)!, 
                                                      options: [AVContentKeyRequestProtocolVersionsKey: [1]]) { [weak self] (spcData, error) in
            
                                                        
            guard let strongSelf = self else { return }
            if let error = error {
                contentKeyRequest.processContentKeyResponseError(error)
                done()
                //                    strongSelf.pendingPersistableContentKeyIdentifiers.remove(assetId)
                return
            }
            
            guard let spcData = spcData else { return }
            
            do {
                // Send SPC to Key Server and obtain CKC
                
                let ckcData = try strongSelf.performCKCRequest(spcData)
                var keyData: Data
                
                if let persReq = contentKeyRequest as? AVPersistableContentKeyRequest {
                    let pKey = try persReq.persistableContentKey(fromKeyVendorResponse: ckcData, options: nil)
                    keyData = pKey
                    
                    try FairPlayUtils.writePersistableContentKey(contentKey: pKey, withContentKeyIdentifier: assetId)
                } else {
                    keyData = ckcData
                }
                
                /*
                 AVContentKeyResponse is used to represent the data returned from the key server when requesting a key for
                 decrypting content.
                 */
                let keyResponse = AVContentKeyResponse(fairPlayStreamingKeyResponseData: keyData)
                
                /*
                 Provide the content key response to make protected content available for processing.
                 */
                contentKeyRequest.processContentKeyResponse(keyResponse)
                
                done()
                //                    strongSelf.pendingPersistableContentKeyIdentifiers.remove(assetId)
            } catch {
                contentKeyRequest.processContentKeyResponseError(error)
                
                done()
                //                    strongSelf.pendingPersistableContentKeyIdentifiers.remove(assetId)
            }
        }
    }

    enum internalError: Error {
        case unknownAssetKeyId
        case unknownAssetMode
        case invalidAssetKeyId
    }
}


class FairPlayUtils {
    static let contentKeyDirectory = try! DefaultLocalDataStore.storageDir()
    
    static func urlForPersistableContentKey(withContentKeyIdentifier contentKeyIdentifier: String) -> URL {
        return contentKeyDirectory.appendingPathComponent("\(contentKeyIdentifier).fpskey")
    }
    
    static func writePersistableContentKey(contentKey: Data, withContentKeyIdentifier contentKeyIdentifier: String) throws {
        
        let fileURL = urlForPersistableContentKey(withContentKeyIdentifier: contentKeyIdentifier)
        
        try contentKey.write(to: fileURL, options: Data.WritingOptions.atomicWrite)
    }
    
    static func persistableContentKeyExistsOnDisk(withContentKeyIdentifier contentKeyIdentifier: String) -> Bool {
        let contentKeyURL = urlForPersistableContentKey(withContentKeyIdentifier: contentKeyIdentifier)
        
        return FileManager.default.fileExists(atPath: contentKeyURL.path)
    }
    
    static func deletePeristableContentKey(withContentKeyIdentifier contentKeyIdentifier: String) {
        
        guard persistableContentKeyExistsOnDisk(withContentKeyIdentifier: contentKeyIdentifier) else { return }
        
        let contentKeyURL = urlForPersistableContentKey(withContentKeyIdentifier: contentKeyIdentifier)
        
        do {
            try FileManager.default.removeItem(at: contentKeyURL)
        } catch {
            print("An error occured removing the persisted content key: \(error)")
        }
    }
}
