
import Foundation
import AVFoundation
import SwiftyJSON

class FPSLicenseHelper {
    
    let assetId: String
    
    let params: FairPlayDRMParams?
    
    let forceDownload: Bool
    let shouldPersist: Bool
    
    let dataStore: LocalDataStore?
    
    var doneCallback: ((Error?) -> Void)?
    
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

    func handleLicenseRequest(_ request: FPSLicenseRequest, done callback: @escaping (Error?) -> Void) {
        
        let done: (Error?) -> Void = { [unowned self] error in 
            callback(error)
            self.doneCallback?(error)
        }
        
        let assetId = self.assetId
        
        if let store = self.dataStore {
            if !forceDownload && store.fpsKeyExists(assetId) {
                do {
                    let license = try store.loadFPSKey(assetId)
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
        
        
        guard let params = FPSParams(self.params) else { 
            done(FPSError.missingDRMParams); 
            return
        }
        
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
                    request.processContentKeyResponseError(error)
                    done(error)
                    return
                }
                                
                if shouldPersist {
                    do {
                        let pck = try request.persistableContentKey(fromKeyVendorResponse: license.data, options: nil)
                        license.data = pck
                        
                        try dataStore?.saveFPSKey(assetId, license)
                        
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

