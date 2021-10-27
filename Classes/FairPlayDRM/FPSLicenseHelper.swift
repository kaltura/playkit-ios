// ===================================================================================================
// Copyright (C) 2018 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================


import Foundation
import AVFoundation
import SwiftyJSON

import PlayKitUtils

struct KalturaLicenseResponseContainer: Codable {
    var ckc: String?
    var persistence_duration: TimeInterval?
}

class KalturaFairPlayLicenseProvider: FairPlayLicenseProvider {
    
    static let sharedInstance = KalturaFairPlayLicenseProvider()
    
    func getLicense(spc: Data, assetId: String, requestParams: PKRequestParams, callback: @escaping (Data?, TimeInterval, Error?) -> Void) {
        var request = URLRequest(url: requestParams.url)
        
        // uDRM requires application/octet-stream as the content type.
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        
        // Also add the user agent
        request.setValue(PlayKitManager.userAgent, forHTTPHeaderField: "User-Agent")
        
        // Add other optional headers
        if let headers = requestParams.headers {
            for (header, value) in headers {
                request.setValue(value, forHTTPHeaderField: header)
            }
        }
        
        request.httpBody = spc.base64EncodedData()
        request.httpMethod = "POST"
        
        PKLog.debug("Sending SPC to server")
        let startTime = Date.timeIntervalSinceReferenceDate
        let dataTask = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            
            if let error = error {
                callback(nil, 0, FPSError.serverError(error, requestParams.url))
                return
            }

            do {
                let endTime: Double = Date.timeIntervalSinceReferenceDate
                PKLog.debug("Got response in \(endTime-startTime) sec")
                
                guard let data = data, data.count > 0 else {
                    callback(nil, 0, FPSError.malformedServerResponse)
                    return
                }
                
                let lic = try JSONDecoder().decode(KalturaLicenseResponseContainer.self, from: data)
                
                guard let ckc = lic.ckc else {
                    callback(nil, 0, FPSError.noCKCInResponse)
                    return
                }
                
                guard let ckcData = Data(base64Encoded: ckc) else {
                    callback(nil, 0, FPSError.malformedCKCInResponse)
                    return
                }
                
                callback(ckcData, lic.persistence_duration ?? 0, nil)
                
            } catch let e {
                callback(nil, 0, e)
            }
        }
        dataTask.resume()
    }
}

class FPSLicenseHelper {
    
    let assetId: String
    
    // Available from iOS 10.3
    var avContentKeyRequest: AnyObject?
    
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
    
    func performCKCRequest(_ spcData: Data, assetId: String, url: URL, callback: @escaping (FPSLicense?, Error?) -> Void) {
        
        
        var requestParams = PKRequestParams(url: url, headers: nil)
        
        if let adapter = self.params?.requestAdapter {
            requestParams = adapter.adapt(requestParams: requestParams)
        }
        
        let licenseProvider = self.params?.licenseProvider ?? KalturaFairPlayLicenseProvider.sharedInstance

        licenseProvider.getLicense(spc: spcData, assetId: assetId,
                                               requestParams: requestParams) { (ckc, duration, error) in
                                                
                                                guard let ckc = ckc else {
                                                    callback(nil, error)
                                                    return
                                                }
                                                
                                                callback(FPSLicense(ckc: ckc, duration: duration), nil)
        }
    }

    func handleLicenseRequest(_ request: FPSLicenseRequest, done callback: @escaping (Error?) -> Void) {
        
        let done: (Error?) -> Void = { [weak self] error in
            guard let self = self else { return }
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
            
            guard let self = self else { return }
            if let error = error {
                request.processContentKeyResponseError(error)
                done(error)
                return
            }
            
            guard let spcData = spcData else { return }
            
            // Send SPC to Key Server and obtain CKC
            self.performCKCRequest(spcData, assetId: assetId, url: params.url) { (license, error) in
                guard let license = license else {
                    request.processContentKeyResponseError(error)
                    done(error)
                    return
                }
                                
                if shouldPersist {
                    
                    if license.isExpired() {
                        let error = FPSError.invalidLicenseDuration
                        request.processContentKeyResponseError(error)
                        done(error)
                        return
                    }
                    
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
