//
//  FPSLicenseHelper.swift
//  PlayKit
//
//  Created by Noam Tamim on 14/03/2018.
//

import Foundation
import AVFoundation
import SwiftyJSON

enum FairPlayError : Error {
    case emptyServerResponse
    case malformedServerResponse
    case noCKCInResponse
    case malformedCKCInResponse
    case noLicenseURL
    case noAppCertificate
}


class FPSLicenseHelper {
    
    let assetId: String
    let appCertificate: Data
    let licenseUrl: URL
    let forceDownload: Bool
    

    init(assetId: String, params: FairPlayDRMParams, forceDownload: Bool = false) throws {
        self.assetId = assetId
        
        guard let cert = params.fpsCertificate else {throw FairPlayError.noAppCertificate}
        guard let url = params.licenseUri else { throw FairPlayError.noLicenseURL }
        
        self.appCertificate = cert
        self.licenseUrl = url
        
        self.forceDownload = forceDownload
    }
    
    @available(iOS 10.3, *)
    convenience init(keyIdentifier: Any?, params: FairPlayDRMParams) throws {
        try self.init(assetId: FPSLicenseHelper.getAssetId(keyIdentifier: keyIdentifier), params: params)
    }
    
    @available(iOS 10.3, *)
    func requestPersistableContentKeys() {
        let skdURL = "skd://" + assetId
        
        FPSContentKeyManager.shared.contentKeySession.processContentKeyRequest(withIdentifier: skdURL, initializationData: nil, options: nil)
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
        
        var request = URLRequest(url: licenseUrl)
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.httpBody = spcData.base64EncodedData()
        request.httpMethod = "POST"
        
        PKLog.debug("Sending SPC to server");
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

    
    @available(iOS 10.3, *)
    func fetchLicense(with keyRequest: AVContentKeyRequest, done: @escaping ()->Void) throws {
        let assetId = try FPSLicenseHelper.getAssetId(keyRequest)
        let keyLocation = FairPlayUtils.urlForPersistableContentKey(withContentKeyIdentifier: assetId)
        
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
        
        keyRequest.makeStreamingContentKeyRequestData(forApp: appCertificate, 
                                                      contentIdentifier: assetId.data(using: .utf8)!, 
                                                      options: [AVContentKeyRequestProtocolVersionsKey: [1]]) { [weak self] (spcData, error) in
            
            guard let strongSelf = self else { return }
            if let error = error {
                keyRequest.processContentKeyResponseError(error)
                done()
                //                    strongSelf.pendingPersistableContentKeyIdentifiers.remove(assetId)
                return
            }
            
            guard let spcData = spcData else { return }
            
            do {
                // Send SPC to Key Server and obtain CKC
                
                let ckcData = try strongSelf.performCKCRequest(spcData)
                var keyData: Data
                
                if let persReq = keyRequest as? AVPersistableContentKeyRequest {
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
                keyRequest.processContentKeyResponse(keyResponse)
                
                done()
                //                    strongSelf.pendingPersistableContentKeyIdentifiers.remove(assetId)
            } catch {
                keyRequest.processContentKeyResponseError(error)
                
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
