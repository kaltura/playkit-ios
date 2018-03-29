
import Foundation
import AVFoundation
import SwiftyJSON

enum FPSError: Error {
    case emptyServerResponse
    case malformedServerResponse
    case noCKCInResponse
    case malformedCKCInResponse
    case missingDRMParams
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
    
    let params: FPSParams?
    
    let forceDownload: Bool
    let shouldPersist: Bool
    
    let dataStore: LocalDataStore?
    
    var done: ((Error?) -> Void)?
    
    // Online play, offline play, download
    init?(assetId: String, params: FPSParams?, dataStore: LocalDataStore?, forceDownload: Bool) {
        
        if params == nil && dataStore == nil {
            PKLog.error("No storage and no DRM params")
            return nil
        }
        
        self.assetId = assetId
        
        self.params = params
        
        self.shouldPersist = dataStore != nil
        self.forceDownload = forceDownload
        
        self.dataStore = dataStore
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
        
        if let store = self.dataStore {
            if !forceDownload && store.fpskeyExists(assetId) {
                do {
                    let storedKey = try store.loadFpsKey(assetId)
                    request.processContentKeyResponse(storedKey)
                    done(nil)
                    
                } catch {
                    request.processContentKeyResponseError(error)
                    done(error)
                }
                return
            }
        }
        
        guard let params = self.params else { done(FPSError.missingDRMParams); return }
        let shouldPersist = self.shouldPersist
        let dataStore = self.dataStore
        
        request.getSPC(cert: params.cert, id: assetId, shouldPersist: shouldPersist) { [weak self] (spcData, error) in                                                                
            
            guard let strongSelf = self else { return }
            if let error = error {
                request.processContentKeyResponseError(error)
                done(error)
                return
            }
            
            guard let spcData = spcData else { return }
            
            // Send SPC to Key Server and obtain CKC
            strongSelf.performCKCRequest(spcData, url: params.url) { (ckcData, error) in 
                guard let ckcData = ckcData else {
                    request.processContentKeyResponseError(error!)
                    done(error)
                    return
                }
                
                var keyData = ckcData
                
                if shouldPersist {
                    do {
                        keyData = try request.persistableContentKey(fromKeyVendorResponse: ckcData, options: nil)
                        try dataStore?.saveFpsKey(assetId, keyData)
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

struct FPSParams {
    let cert: Data
    let url: URL
    init?(_ pkParams: FairPlayDRMParams?) {
        guard let params = pkParams else { return nil }
        guard let cert = params.fpsCertificate else { PKLog.error("Missing FPS certificate"); return nil }
        guard let url = params.licenseUri else { PKLog.error("Missing FPS license URL"); return nil }
        self.cert = cert
        self.url = url
    }
}

extension LocalDataStore {
    
    func fpsKey(_ assetId: String) -> String {
        return assetId + ".fpskey"
    }
    
    func fpskeyExists(_ assetId: String) -> Bool {
        return exists(key: fpsKey(assetId))
    }
    
    func loadFpsKey(_ assetId: String) throws -> Data {
        return try load(key: fpsKey(assetId))
    }
    
    func saveFpsKey(_ assetId: String, _ value: Data) throws {
        try save(key: fpsKey(assetId), value: value)
    }
    
    func removeFpsKey(_ assetId: String) throws {
        try remove(key: fpsKey(assetId))
    }
}
