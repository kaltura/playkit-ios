// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
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


enum FairPlayError : Error {
    case emptyServerResponse
    case malformedServerResponse
    case noCKCInResponse
    case malformedCKCInResponse
}

class AssetLoaderDelegate: NSObject {
    
    /// The URL scheme for FPS content.
    static let customScheme = "skd"
    
    /// Error domain for errors being thrown in the process of getting a CKC.
    static let errorDomain = "AssetLoaderDelegate"
    
    /// Notification for when the persistent content key has been saved to disk.
    static let didPersistContentKeyNotification = NSNotification.Name(rawValue: "handleAssetLoaderDelegateDidPersistContentKeyNotification")
    
    /// The DispatchQueue to use for AVAssetResourceLoaderDelegate callbacks.
    fileprivate static let resourceLoadingRequestQueue = DispatchQueue(label: "com.kaltura.playkit.resourcerequests")
    
    private let storage: LocalDataStore?
    
    private let drmData: FairPlayDRMParams?
    
    var done: ((Error?)->Void)?
    
    var shouldPersist: Bool {
        return storage != nil
    }
    
    private init(drmData: FairPlayDRMParams? = nil, storage: LocalDataStore? = nil) {
        
        self.drmData = drmData
        self.storage = storage
        
        super.init()
    }
    
    static func configureRemotePlay(asset: AVURLAsset, drmData: FairPlayDRMParams) -> AssetLoaderDelegate {
        let delegate = AssetLoaderDelegate.init(drmData: drmData)
        
        asset.resourceLoader.setDelegate(delegate, queue: resourceLoadingRequestQueue)
        
        return delegate
    }
    
    @available(iOS 10.0, *)
    static func configureDownload(asset: AVURLAsset, drmData: FairPlayDRMParams, storage: LocalDataStore) -> AssetLoaderDelegate {
        let delegate = AssetLoaderDelegate.init(drmData: drmData, storage: storage)
        
        asset.resourceLoader.setDelegate(delegate, queue: resourceLoadingRequestQueue)
        asset.resourceLoader.preloadsEligibleContentKeys = true
        
        return delegate
    }
    
    @available(iOS 10.0, *)
    static func configureLocalPlay(asset: AVURLAsset, storage: LocalDataStore) -> AssetLoaderDelegate {
        let delegate = AssetLoaderDelegate.init(storage: storage)
        
        asset.resourceLoader.setDelegate(delegate, queue: resourceLoadingRequestQueue)
        asset.resourceLoader.preloadsEligibleContentKeys = true
        
        return delegate
    }
    
    func parseServerResponse(data: Data?, error: Error?) throws -> Data {
        if let error = error {
            throw error
        }
        
        guard let data = data else {
            throw FairPlayError.emptyServerResponse
        }
        
        var pError: NSError?
        let json = JSON(data: data, options: [], error: &pError)
        if let error = pError {
            throw error
        }
        
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
    
    func performCKCRequest(_ spcData: Data, _ callback: @escaping (_ data:Data?, _ error:Error?)->Void) {
        
        guard let licenseUri = drmData?.licenseUri else { return }
        
        var requestParams = PKRequestParams(url: licenseUri, headers: ["Content-Type": "application/octet-stream"])
        
        if let adapter = drmData?.requestAdapter {
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
        
        PKLog.debug("Sending SPC to server");
        let startTime: Double = Date.timeIntervalSinceReferenceDate
        let dataTask = URLSession.shared.dataTask(with: request, completionHandler: {(data: Data?, response: URLResponse?, error: Error?) -> Void in
            do {
                let endTime: Double = Date.timeIntervalSinceReferenceDate
                PKLog.debug("Got response in \(endTime-startTime) sec")
                let ckc = try self.parseServerResponse(data: data, error: error)
                callback(ckc,nil)
            } catch let e {
                callback(nil,e)
            }
        })
        dataTask.resume()
    }
    
    func persistentKeyName(_ assetId: String) -> String {
        return "\(assetId).fpskey"
    }
    
    func loadPersistedContentKeyData(_ assetId: String) -> Data? {
        do {
            let data = try self.storage?.load(key: persistentKeyName(assetId))
            if data != nil {
                PKLog.debug("Loaded PCKD with \(String(describing: data?.count)) bytes")
            } else {
                PKLog.error("Load PCKD failed (1)")
            }
            return data
        } catch let error {
            PKLog.error("Load PCKD failed (2)", error)
            // TODO: real error handling
            return nil
        }
    }
    
    func savePersistentContentKeyData(_ assetId: String, _ data: Data) {
        do {
            try self.storage?.save(key: persistentKeyName(assetId), value: data)
            PKLog.debug("Saved PCKD")
        } catch {
            PKLog.error("Failed saving PCKD")
            // TODO: real error handling
        }
    }
    
    func prepareAndSendContentKeyRequest(resourceLoadingRequest: AVAssetResourceLoadingRequest) {
        
        guard let url = resourceLoadingRequest.request.url, let assetIDString = url.host else {
            PKLog.error("Failed to get url or assetIDString for the request object of the resource.")
            return
        }
        
        // Check if this reuqest is the result of a potential AVAssetDownloadTask.
        if #available(iOS 10.0, *), shouldPersist {
            if resourceLoadingRequest.contentInformationRequest != nil {
                resourceLoadingRequest.contentInformationRequest!.contentType = AVStreamingKeyDeliveryPersistentContentKeyType
            }
            else {
                PKLog.error("Unable to set contentType on contentInformationRequest.")
                let error = NSError(domain: AssetLoaderDelegate.errorDomain, code: -1, userInfo: nil)
                resourceLoadingRequest.finishLoading(with: error)
                self.done?(error)
                return
            }
        }
        
        // Check if we have an existing key on disk for this asset.
        if let persistedContentKeyData = loadPersistedContentKeyData(assetIDString) {
            guard let dataRequest = resourceLoadingRequest.dataRequest else {
                PKLog.error("Error loading contents of content key file.")
                let error = NSError(domain: AssetLoaderDelegate.errorDomain, code: -2, userInfo: nil)
                resourceLoadingRequest.finishLoading(with: error)
                self.done?(error)
                return
            }
            
            // Pass the persistedContentKeyData into the dataRequest so complete the content key request.
            dataRequest.respond(with: persistedContentKeyData)
            resourceLoadingRequest.finishLoading()
            self.done?(nil)
            
            return
        }
        
        // Get the application certificate.
        guard let applicationCertificate = self.drmData?.fpsCertificate else {
            PKLog.error("Error loading application certificate.")
            let error = NSError(domain: AssetLoaderDelegate.errorDomain, code: -3, userInfo: nil)
            resourceLoadingRequest.finishLoading(with: error)
            self.done?(error)
            return
        }
        
        guard let assetIDData = assetIDString.data(using: String.Encoding.utf8) else {
            PKLog.error("Error retrieving Asset ID.")
            let error = NSError(domain: AssetLoaderDelegate.errorDomain, code: -4, userInfo: nil)
            resourceLoadingRequest.finishLoading(with: error)
            self.done?(error)
            return
        }
        
        var resourceLoadingRequestOptions: [String: AnyObject]? = nil
        
        if #available(iOS 10.0, *), shouldPersist {
            resourceLoadingRequestOptions = [AVAssetResourceLoadingRequestStreamingContentKeyRequestRequiresPersistentKey: true as AnyObject]
        }
        
        let spcData: Data!
        
        do {
            /*
             To obtain the Server Playback Context (SPC), we call
             AVAssetResourceLoadingRequest.streamingContentKeyRequestData(forApp:contentIdentifier:options:)
             using the information we obtained earlier.
             */
            spcData = try resourceLoadingRequest.streamingContentKeyRequestData(forApp: applicationCertificate, contentIdentifier: assetIDData, options: resourceLoadingRequestOptions)
            PKLog.debug("Got spcData with", spcData.count, "bytes")
        } catch let error as NSError {
            PKLog.error("Error obtaining key request data: \(error.domain) reason: \(String(describing: error.localizedFailureReason))")
            resourceLoadingRequest.finishLoading(with: error)
            self.done?(error)
            return
        }
        
        /*
         Send the SPC message (requestBytes) to the Key Server and get a CKC in reply.
         
         The Key Server returns the CK inside an encrypted Content Key Context (CKC) message in response to
         the app’s SPC message.  This CKC message, containing the CK, was constructed from the SPC by a
         Key Security Module in the Key Server’s software.
         
         When a KSM receives an SPC with a media playback state TLLV, the SPC may include a content key duration TLLV
         in the CKC message that it returns. If the Apple device finds this type of TLLV in a CKC that delivers an FPS
         content key, it will honor the type of rental or lease specified when the key is used.
         */
        
        performCKCRequest(spcData) { (data,error) in
            if let ckcData = data {
                self.handleCKCData(resourceLoadingRequest, assetIDString, ckcData)
            } else {
                PKLog.error("Error occured while loading FairPlay license:", error ?? "")
            }
        }
        
    }
    
    func handleCKCData(_ resourceLoadingRequest: AVAssetResourceLoadingRequest, _ assetId: String, _ ckcData: Data) {
        
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
                self.savePersistentContentKeyData(assetId, persistentContentKeyData)
                
                guard let dataRequest = resourceLoadingRequest.dataRequest else {
                    PKLog.error("no data is being requested in loadingRequest")
                    let error = NSError(domain: AssetLoaderDelegate.errorDomain, code: -6, userInfo: nil)
                    resourceLoadingRequest.finishLoading(with: error)
                    self.done?(error)
                    return
                }
                // Provide data to the loading request.
                dataRequest.respond(with: persistentContentKeyData)
                resourceLoadingRequest.finishLoading()  // Treat the processing of the request as complete.
                self.done?(nil)
            } catch {
                PKLog.error("Error creating persistent content key: \(error)")
                resourceLoadingRequest.finishLoading(with: error)
                self.done?(error)
                return
            }
        } else {
            
            guard let dataRequest = resourceLoadingRequest.dataRequest else {
                PKLog.error("no data is being requested in loadingRequest")
                let error = NSError(domain: AssetLoaderDelegate.errorDomain, code: -6, userInfo: nil)
                resourceLoadingRequest.finishLoading(with: error)
                self.done?(error)
                return
            }
            
            // Provide data to the loading request.
            dataRequest.respond(with: ckcData)
            resourceLoadingRequest.finishLoading()  // Treat the processing of the request as complete.
            self.done?(nil)
        }
    }
    
    
    func shouldLoadOrRenewRequestedResource(resourceLoadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        
        guard let url = resourceLoadingRequest.request.url else {
            return false
        }
        
        // AssetLoaderDelegate only should handle FPS Content Key requests.
        if url.scheme != AssetLoaderDelegate.customScheme {
            return false
        }
        
        AssetLoaderDelegate.resourceLoadingRequestQueue.async {
            self.prepareAndSendContentKeyRequest(resourceLoadingRequest: resourceLoadingRequest)
        }
        
        return true
    }
}

//MARK:- AVAssetResourceLoaderDelegate protocol methods extension
extension AssetLoaderDelegate: AVAssetResourceLoaderDelegate {
    
    /*
     resourceLoader:shouldWaitForLoadingOfRequestedResource:
     
     When iOS asks the app to provide a CK, the app invokes
     the AVAssetResourceLoader delegate’s implementation of
     its -resourceLoader:shouldWaitForLoadingOfRequestedResource:
     method. This method provides the delegate with an instance
     of AVAssetResourceLoadingRequest, which accesses the
     underlying NSURLRequest for the requested resource together
     with support for responding to the request.
     */
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        
        PKLog.trace("\(#function) was called in AssetLoaderDelegate with loadingRequest: \(loadingRequest)")
        
        return shouldLoadOrRenewRequestedResource(resourceLoadingRequest: loadingRequest)
    }
    
    
    /*
     resourceLoader: shouldWaitForRenewalOfRequestedResource:
     
     Delegates receive this message when assistance is required of the application
     to renew a resource previously loaded by
     resourceLoader:shouldWaitForLoadingOfRequestedResource:. For example, this
     method is invoked to renew decryption keys that require renewal, as indicated
     in a response to a prior invocation of
     resourceLoader:shouldWaitForLoadingOfRequestedResource:. If the result is
     YES, the resource loader expects invocation, either subsequently or
     immediately, of either -[AVAssetResourceRenewalRequest finishLoading] or
     -[AVAssetResourceRenewalRequest finishLoadingWithError:]. If you intend to
     finish loading the resource after your handling of this message returns, you
     must retain the instance of AVAssetResourceRenewalRequest until after loading
     is finished. If the result is NO, the resource loader treats the loading of
     the resource as having failed. Note that if the delegate's implementation of
     -resourceLoader:shouldWaitForRenewalOfRequestedResource: returns YES without
     finishing the loading request immediately, it may be invoked again with
     another loading request before the prior request is finished; therefore in
     such cases the delegate should be prepared to manage multiple loading
     requests.
     */
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForRenewalOfRequestedResource renewalRequest: AVAssetResourceRenewalRequest) -> Bool {
        
        PKLog.trace("\(#function) was called in AssetLoaderDelegate with renewalRequest: \(renewalRequest)")
        
        return shouldLoadOrRenewRequestedResource(resourceLoadingRequest: renewalRequest)
    }
    
}
