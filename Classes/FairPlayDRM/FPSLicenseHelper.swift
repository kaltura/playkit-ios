
import Foundation
import AVFoundation
import SwiftyJSON

enum FPSError: Error {
    case emptyServerResponse
    case malformedServerResponse
    case noCKCInResponse
    case malformedCKCInResponse
    case noLicenseURL
    case noAppCertificate
    case invalidKeyRequest
    case persistenceNotSupported
}

enum FPSInternalError: Error {
    case unknownAssetKeyId
    case unknownAssetMode
    case invalidAssetKeyId
}


protocol FPSLicenseRequest {
    func getSPC(cert: Data, id: String, shouldPersist: Bool, callback: @escaping (Data?, Error?) -> Void)
    func processContentKeyResponse(_ keyResponse: Data)
    func processContentKeyResponseError(_ error: Error)
    func persistableContentKey(fromKeyVendorResponse keyVendorResponse: Data, options: [String : Any]?) throws -> Data
}


class FPSLicenseHelper {
    
    let assetId: String
    
    let appCertificate: Data?
    let licenseUrl: URL?
    
    let forceDownload: Bool
    let shouldPersist: Bool

    init(assetId: String, params: FairPlayDRMParams, shouldPersist: Bool, forceDownload: Bool = false) throws {
        self.assetId = assetId
        
        guard let cert = params.fpsCertificate else {throw FPSError.noAppCertificate}
        guard let url = params.licenseUri else { throw FPSError.noLicenseURL }
        
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
            let url = URL(string: keyId), let assetId = url.host else { throw FPSInternalError.invalidAssetKeyId }
        return assetId
    }
    
    func performCKCRequest(_ spcData: Data, url: URL, callback: @escaping (Data?, Error?) -> Void) {
        
        var request = URLRequest(url: url)
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.httpBody = spcData.base64EncodedData()
        request.httpMethod = "POST"
        
        PKLog.debug("Sending SPC to server")
        let startTime = Date.timeIntervalSinceReferenceDate
        let dataTask = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            do {
                let endTime: Double = Date.timeIntervalSinceReferenceDate
                PKLog.debug("Got response in \(endTime-startTime) sec")
                let ckc = try self.parseServerResponse(data: data)
                callback(ckc, nil)
            } catch let e {
                callback(nil, e)
            }
        }
        dataTask.resume()
    }

    func parseServerResponse(data: Data?) throws -> Data {
        guard let data = data else {
            throw FPSError.emptyServerResponse
        }
        
        let json = JSON(data: data, options: [])
        
        guard let b64CKC = json["ckc"].string else {
            throw FPSError.noCKCInResponse
        }
        
        guard let ckc = Data(base64Encoded: b64CKC) else {
            throw FPSError.malformedCKCInResponse
        }
        
        if ckc.count == 0 {
            throw FPSError.malformedCKCInResponse
        }
        
        PKLog.debug("Got valid CKC")
        
        return ckc
    }
    
    func handleLicenseRequest(_ request: FPSLicenseRequest, done: @escaping (Error?) -> Void) {
        let assetId = self.assetId
        let keyLocation = FairPlayUtils.urlForPersistableContentKey(withContentKeyIdentifier: assetId)
        
        if !forceDownload && FileManager.default.fileExists(atPath: keyLocation.path) {
            if let storedKey = try? Data.init(contentsOf: keyLocation) {
                request.processContentKeyResponse(storedKey)
            }
            return
        }
        
        guard let appCert = self.appCertificate else { done(FPSError.noAppCertificate); return }
        guard let licenseUrl = self.licenseUrl else { done(FPSError.noLicenseURL); return }
        let shouldPersist = self.shouldPersist
        
        request.getSPC(cert: appCert, id: assetId, shouldPersist: shouldPersist) { [weak self] (spcData, error) in                                                                
            
            guard let strongSelf = self else { return }
            if let error = error {
                request.processContentKeyResponseError(error)
                done(error)
                return
            }
            
            guard let spcData = spcData else { return }
            
            // Send SPC to Key Server and obtain CKC
            strongSelf.performCKCRequest(spcData, url: licenseUrl) { (ckcData, error) in 
                guard let ckcData = ckcData else {
                    request.processContentKeyResponseError(error!)
                    done(error)
                    return
                }
                
                var keyData = ckcData
                
                if shouldPersist {
                    do {
                        keyData = try request.persistableContentKey(fromKeyVendorResponse: ckcData, options: nil)
                        try FairPlayUtils.writePersistableContentKey(contentKey: keyData, withContentKeyIdentifier: assetId)
                    } catch {
                        request.processContentKeyResponseError(error)
                        done(error)
                        return
                    }
                }
                
                request.processContentKeyResponse(keyData)
                
                done(nil)
            }
        }
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
