
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
    case invalidKeyRequest
}


protocol FPSContentKeyHandler {
    func getSPC(cert: Data, id: String, options: [String : Any]?, callback: @escaping (Data?, Error?) -> Void)
    func processContentKeyResponse(_ keyResponse: Data)
    func processContentKeyResponseError(_ error: Error)
    func respondByRequestingPersistableContentKeyRequest()
    func persistableContentKey(fromKeyVendorResponse keyVendorResponse: Data, options: [String : Any]?) throws -> Data
}

@available(iOS 9.0, *)
class FPSResourceLoadingKeyRequest: FPSContentKeyHandler {
    let request: AVAssetResourceLoadingRequest
    init(_ request: AVAssetResourceLoadingRequest) {
        self.request = request
    }
    
    func getSPC(cert: Data, id: String, options: [String : Any]?, callback: @escaping (Data?, Error?) -> Void) {
        do {
            let spc = try request.streamingContentKeyRequestData(forApp: cert, contentIdentifier: id.data(using: .utf8)!, options: options)
            callback(spc, nil)
        } catch {
            callback(nil, error)
        }
    }
    
    func processContentKeyResponse(_ keyResponse: Data) {
        guard let dataRequest = request.dataRequest else { 
            request.finishLoading(with: FairPlayError.invalidKeyRequest)
            return
        }

        dataRequest.respond(with: keyResponse)
        request.finishLoading()
    }
    
    func processContentKeyResponseError(_ error: Error) {
        request.finishLoading(with: error)
    }
    
    func respondByRequestingPersistableContentKeyRequest() {
        fatalError("Invalid state")
    }
    
    func persistableContentKey(fromKeyVendorResponse keyVendorResponse: Data, options: [String : Any]?) throws -> Data {
        return try request.persistentContentKey(fromKeyVendorResponse: keyVendorResponse, options: options)
    }
}

@available(iOS 10.3, *)
class FPSContentKeyRequest: FPSContentKeyHandler {
    let request: AVContentKeyRequest
    init(_ request: AVContentKeyRequest) {
        self.request = request
    }
    
    func getSPC(cert: Data, id: String, options: [String : Any]?, callback: @escaping (Data?, Error?) -> Void) {
        request.makeStreamingContentKeyRequestData(forApp: cert, contentIdentifier: id.data(using: .utf8)!, options: options, completionHandler: callback)
    }
    
    func processContentKeyResponse(_ keyResponse: Data) {
        request.processContentKeyResponse(AVContentKeyResponse(fairPlayStreamingKeyResponseData: keyResponse))
    }
    
    func processContentKeyResponseError(_ error: Error) {
        request.processContentKeyResponseError(error)
    }
    
    func respondByRequestingPersistableContentKeyRequest() {
        request.respondByRequestingPersistableContentKeyRequest()
    }
    
    func persistableContentKey(fromKeyVendorResponse keyVendorResponse: Data, options: [String : Any]?) throws -> Data {
        if let request = self.request as? AVPersistableContentKeyRequest {
            return try request.persistableContentKey(fromKeyVendorResponse: keyVendorResponse, options: options)
        }
        fatalError("Invalid state")
    }
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
    
    func performCKCRequest(_ spcData: Data, url: URL, callback: @escaping (Data?, Error?) -> Void) {
        
        var request = URLRequest(url: url)
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.httpBody = spcData.base64EncodedData()
        request.httpMethod = "POST"
        
        PKLog.debug("Sending SPC to server")
        let startTime = Date.timeIntervalSinceReferenceDate
        let dataTask = URLSession.shared.dataTask(with: request, completionHandler: {(data: Data?, response: URLResponse?, error: Error?) -> Void in
            do {
                let endTime: Double = Date.timeIntervalSinceReferenceDate
                PKLog.debug("Got response in \(endTime-startTime) sec")
                let ckc = try self.parseServerResponse(data: data)
                callback(ckc,nil)
            } catch let e {
                callback(nil,e)
            }
        })
        dataTask.resume()
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

    func fetchLicense(resourceLoadingRequest: AVAssetResourceLoadingRequest, done: @escaping (Error?) -> Void) throws {
        // Check if we have an existing key on disk for this asset.
        let keyLocation = FairPlayUtils.urlForPersistableContentKey(withContentKeyIdentifier: assetId)
        
        if !forceDownload && FileManager.default.fileExists(atPath: keyLocation.path) {
            guard let dataRequest = resourceLoadingRequest.dataRequest else { 
                resourceLoadingRequest.finishLoading(with: FairPlayError.invalidKeyRequest)
                done(FairPlayError.invalidKeyRequest) 
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
        guard let licenseUrl = self.licenseUrl else { throw FairPlayError.noLicenseURL }
        
        var resourceLoadingRequestOptions: [String: AnyObject]? = nil
        
        if #available(iOS 10.0, *), shouldPersist {
            resourceLoadingRequestOptions = [AVAssetResourceLoadingRequestStreamingContentKeyRequestRequiresPersistentKey: true as AnyObject]
        }
        
        let spcData: Data!
        
        do {
            spcData = try resourceLoadingRequest.streamingContentKeyRequestData(forApp: appCert, contentIdentifier: assetId.data(using: .utf8)!, options: resourceLoadingRequestOptions)
            PKLog.debug("Got spcData with", spcData.count, "bytes")
        } catch let error as NSError {
            PKLog.error("Error obtaining key request data:", error.localizedFailureReason ?? "??")
            resourceLoadingRequest.finishLoading(with: error)
            done(error)
            return
        }
        
        performCKCRequest(spcData, url: licenseUrl) { (ckcData, error) in
            if let ckcData = ckcData {
                self.handleCKCData(resourceLoadingRequest, ckcData: ckcData, done: done)
            } else {
                PKLog.error("Error occured while loading FairPlay license:", error)
            }
        }
    }

    func handleCKCData(_ resourceLoadingRequest: AVAssetResourceLoadingRequest, ckcData: Data, done: (Error?) -> Void) {
        
        // Check if this reuqest is the result of a potential AVAssetDownloadTask.
        if #available(iOS 10.0, *), shouldPersist {
            do {
                let persistentContentKeyData = try resourceLoadingRequest.persistentContentKey(fromKeyVendorResponse: ckcData, options: nil)
                
                // Save the persistentContentKeyData onto disk for use in the future.
                PKLog.debug("Saving persistentContentKeyData")
                try FairPlayUtils.writePersistableContentKey(contentKey: persistentContentKeyData, withContentKeyIdentifier: assetId)
                
                guard let dataRequest = resourceLoadingRequest.dataRequest else { 
                    resourceLoadingRequest.finishLoading(with: FairPlayError.invalidKeyRequest)
                    done(FairPlayError.invalidKeyRequest)
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
                resourceLoadingRequest.finishLoading(with: FairPlayError.invalidKeyRequest)
                done(FairPlayError.invalidKeyRequest)
                return
            }
            
            // Provide data to the loading request.
            dataRequest.respond(with: ckcData)
            resourceLoadingRequest.finishLoading()  // Treat the processing of the request as complete.
            done(nil)
        }
    }
    
    @available(iOS 10.3, *)
    func fetchLicense(contentKeyRequest: AVContentKeyRequest, done: @escaping (Error?) -> Void) throws {
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
        guard let licenseUrl = self.licenseUrl else { throw FairPlayError.noLicenseURL }

        contentKeyRequest.makeStreamingContentKeyRequestData(forApp: appCert, 
                                                      contentIdentifier: assetId.data(using: .utf8)!, 
                                                      options: [AVContentKeyRequestProtocolVersionsKey: [1]]) { [weak self] (spcData, error) in
            
                                                        
            guard let strongSelf = self else { return }
            if let error = error {
                contentKeyRequest.processContentKeyResponseError(error)
                done(error)
                return
            }
            
            guard let spcData = spcData else { return }
            
            // Send SPC to Key Server and obtain CKC
            strongSelf.performCKCRequest(spcData, url: licenseUrl) { (ckcData, error) in 
                guard let ckcData = ckcData else {
                    contentKeyRequest.processContentKeyResponseError(error!)
                    done(error)
                    return
                }
                
                var keyData = ckcData
                
                if let persReq = contentKeyRequest as? AVPersistableContentKeyRequest {
                    do {
                        keyData = try persReq.persistableContentKey(fromKeyVendorResponse: ckcData, options: nil)
                        
                        try FairPlayUtils.writePersistableContentKey(contentKey: keyData, withContentKeyIdentifier: assetId)
                    } catch {
                        contentKeyRequest.processContentKeyResponseError(error)
                        done(error)
                        return
                    }
                }
                
                let keyResponse = AVContentKeyResponse(fairPlayStreamingKeyResponseData: keyData)
                
                contentKeyRequest.processContentKeyResponse(keyResponse)
                
                done(nil)

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
