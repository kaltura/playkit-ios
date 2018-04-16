
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
    
    let params: FairPlayDRMParams?
    
    let forceDownload: Bool
    let shouldPersist: Bool
    
    let dataStore: LocalDataStore?
    
    var done: ((Error?) -> Void)?
    
    // Online play, offline play, download
    init?(assetId: String, params: FairPlayDRMParams?, dataStore: LocalDataStore?, forceDownload: Bool) {
        
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
    
    func performCKCRequest(_ spcData: Data, url: URL, callback: @escaping (FPSLicense?, Error?) -> Void) {
        
        
        var requestParams = PKRequestParams(url: url, headers: ["Content-Type": "application/octet-stream"])

        if let adapter = self.params?.requestAdapter {
            requestParams = adapter.adapt(requestParams: requestParams)
        }
        
        var request = URLRequest(url: requestParams.url)
        if let headers = requestParams.headers {
            for (header, value) in headers {
                request.setValue(value, forHTTPHeaderField: header)
            }
        }

        request.httpBody = spcData.base64EncodedData()
        request.httpMethod = "POST"
        
        PKLog.debug("Sending SPC to server")
        let startTime = Date.timeIntervalSinceReferenceDate
        let dataTask = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            do {
                let endTime: Double = Date.timeIntervalSinceReferenceDate
                PKLog.debug("Got response in \(endTime-startTime) sec")
                let lic = try FPSLicense(jsonResponse: data)
                callback(lic, nil)
                
            } catch let e {
                callback(nil, e)
            }
        }
        dataTask.resume()
    }

    func handleLicenseRequest(_ request: FPSLicenseRequest, done: @escaping (Error?) -> Void) {
        let assetId = self.assetId
        
        if let store = self.dataStore {
            if !forceDownload && store.fpskeyExists(assetId) {
                do {
                    let license = try store.loadFpsKey(assetId)
                    if !license.isExpired() {
                        request.processContentKeyResponse(license.data)
                        done(nil)
                    }
                    
                } catch {
                    request.processContentKeyResponseError(error)
                    done(error)
                }
                return
            }
        }
        
        
        guard let params = FPSParams(self.params) else { done(FPSError.missingDRMParams); return }
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
            strongSelf.performCKCRequest(spcData, url: params.url) { (license, error) in 
                guard let license = license else {
                    request.processContentKeyResponseError(error!)
                    done(error)
                    return
                }
                                
                if shouldPersist {
                    do {
                        let pck = try request.persistableContentKey(fromKeyVendorResponse: license.data, options: nil)
                        license.data = pck
                        
                        try dataStore?.saveFpsKey(assetId, license)
                        
                    } catch {
                        request.processContentKeyResponseError(error)
                        done(error)
                        return
                    }
                }
                
                request.processContentKeyResponse(license.data)
                
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

class FPSLicense: Codable {
    static let defaultExpiry: TimeInterval = 7*24*60*60
    let expiryDate: Date?
    var data: Data
    
    init(jsonResponse: Data?) throws {
        guard let data = jsonResponse else {
            throw FPSError.emptyServerResponse
        }
        
        let json = JSON(data: data, options: [])
        
        guard let b64CKC = json["ckc"].string else {
            throw FPSError.noCKCInResponse
        }
        
        guard let ckc = Data(base64Encoded: b64CKC) else {
            throw FPSError.malformedCKCInResponse
        }
        
        let expiry = json["expiry"].double ?? FPSLicense.defaultExpiry
        
        if ckc.count == 0 {
            throw FPSError.malformedCKCInResponse
        }
        
        self.data = ckc
        self.expiryDate = Date(timeIntervalSinceNow: expiry)
    }
    
    init(legacyData: Data) {
        self.data = legacyData
        self.expiryDate = nil
    }
    
    func isExpired() -> Bool {
        if let expiryDate = self.expiryDate {
            return Date() > expiryDate
        }
        return false
    }
}

extension LocalDataStore {
    
    func fpsKey(_ assetId: String) -> String {
        return assetId + ".fpskey"
    }
    
    func fpskeyExists(_ assetId: String) -> Bool {
        return exists(key: fpsKey(assetId))
    }
    
    func loadFpsKey(_ assetId: String) throws -> FPSLicense {
        let obj = try load(key: fpsKey(assetId))

        if let license = try? JSONDecoder().decode(FPSLicense.self, from: obj) {
            return license
        } else {
            return FPSLicense(legacyData: obj)
        }
    }
    
    func saveFpsKey(_ assetId: String, _ value: FPSLicense) throws {
        let json = try JSONEncoder().encode(value)
        try save(key: fpsKey(assetId), value: json)
    }
    
    func removeFpsKey(_ assetId: String) throws {
        try remove(key: fpsKey(assetId))
    }
}
