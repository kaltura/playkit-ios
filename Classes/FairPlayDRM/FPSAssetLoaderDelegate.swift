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


class FPSAssetLoaderDelegate: NSObject {
    
    /// The URL scheme for FPS content.
    static let customScheme = "skd"
    
    fileprivate static let fpsDownloadResourceLoadingRequestQueue = DispatchQueue(label: "com.kaltura.playkit.fps_resourcerequests")
    
    private let storage: LocalDataStore?
    
    private let drmData: FairPlayDRMParams?
    
    private let forceDownload: Bool
    
    var done: ((Error?) -> Void)?
    
    var shouldPersist: Bool {
        return storage != nil
    }
    
    private init(drmData: FairPlayDRMParams? = nil, storage: LocalDataStore? = nil, forceDownload: Bool = false) {
        
        self.drmData = drmData
        self.storage = storage
        self.forceDownload = forceDownload
        
        super.init()
    }
    
    static func configureRemotePlay(asset: AVURLAsset, drmData: FairPlayDRMParams) -> FPSAssetLoaderDelegate {
        let delegate = FPSAssetLoaderDelegate.init(drmData: drmData)

        return delegate
    }
    
    @available(iOS 10.0, *)
    static func configureDownload(asset: AVURLAsset, drmData: FairPlayDRMParams, storage: LocalDataStore) -> FPSAssetLoaderDelegate {
        let delegate = FPSAssetLoaderDelegate.init(drmData: drmData, storage: storage, forceDownload: true)
        
        asset.resourceLoader.setDelegate(delegate, queue: fpsDownloadResourceLoadingRequestQueue)
        asset.resourceLoader.preloadsEligibleContentKeys = true
        
        return delegate
    }
    
    @available(iOS 10.0, *)
    static func configureLocalPlay(asset: AVURLAsset, storage: LocalDataStore) -> FPSAssetLoaderDelegate {
        let delegate = FPSAssetLoaderDelegate.init(storage: storage)
        
        asset.resourceLoader.preloadsEligibleContentKeys = false

        return delegate
    }
    
    func prepareAndSendContentKeyRequest(resourceLoadingRequest: AVAssetResourceLoadingRequest) {
        
        guard let assetId = resourceLoadingRequest.request.url?.host else {
            PKLog.error("No asset id")
            return
        }
        
        // Check if this reuqest is the result of a potential AVAssetDownloadTask.
        if #available(iOS 10.0, *), shouldPersist {
            if let cir = resourceLoadingRequest.contentInformationRequest {
                cir.contentType = AVStreamingKeyDeliveryPersistentContentKeyType
            }
        }
        
        guard let helper = FPSLicenseHelper.init(assetId: assetId, params: self.drmData, 
                                                 dataStore: self.storage, forceDownload: self.forceDownload) else { return }
        
        helper.handleLicenseRequest(FPSResourceLoadingKeyRequest(resourceLoadingRequest)) { (error) in
            self.done?(error)
        }
    }

    func shouldLoadOrRenewRequestedResource(_ resourceLoader: AVAssetResourceLoader, loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        
        guard let url = loadingRequest.request.url else {
            return false
        }
        
        // AssetLoaderDelegate only should handle FPS Content Key requests.
        if url.scheme != FPSAssetLoaderDelegate.customScheme {
            return false
        }
        
        resourceLoader.delegateQueue?.async {
            self.prepareAndSendContentKeyRequest(resourceLoadingRequest: loadingRequest)
        }
        
        return true
    }
}

//MARK:- AVAssetResourceLoaderDelegate protocol methods extension
extension FPSAssetLoaderDelegate: AVAssetResourceLoaderDelegate {
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        
        PKLog.verbose("\(#function) was called in FPSAssetLoaderDelegate with loadingRequest: \(loadingRequest)")
        
        return shouldLoadOrRenewRequestedResource(resourceLoader, loadingRequest: loadingRequest)
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForRenewalOfRequestedResource renewalRequest: AVAssetResourceRenewalRequest) -> Bool {
        
        PKLog.verbose("\(#function) was called in FPSAssetLoaderDelegate with renewalRequest: \(renewalRequest)")
        
        return shouldLoadOrRenewRequestedResource(resourceLoader, loadingRequest: renewalRequest)
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        PKLog.verbose("\(#function) was called in FPSAssetLoaderDelegate with loadingRequest: \(loadingRequest)")
    }
}

//MARK:- FPSAssetLoaderDelegate version of FPSLicenseRequest
class FPSResourceLoadingKeyRequest: FPSLicenseRequest {
    
    let request: AVAssetResourceLoadingRequest
    
    init(_ request: AVAssetResourceLoadingRequest) {
        self.request = request
    }
    
    func getSPC(cert: Data, id: String, shouldPersist: Bool, callback: @escaping (Data?, Error?) -> Void) {
        var options: [String: AnyObject]? = nil
        
        if #available(iOS 10.0, *), shouldPersist {
            options = [AVAssetResourceLoadingRequestStreamingContentKeyRequestRequiresPersistentKey: true as AnyObject]
        }
        
        do {
            let spc = try request.streamingContentKeyRequestData(forApp: cert, contentIdentifier: id.data(using: .utf8)!, options: options)
            callback(spc, nil)
        } catch {
            callback(nil, error)
        }
    }
    
    func processContentKeyResponse(_ keyResponse: Data) {
        guard let dataRequest = request.dataRequest else { 
            request.finishLoading(with: FPSError.invalidKeyRequest)
            return
        }
        
        dataRequest.respond(with: keyResponse)
        request.finishLoading()
    }
    
    func processContentKeyResponseError(_ error: Error?) {
        request.finishLoading(with: error)
    }
    
    func persistableContentKey(fromKeyVendorResponse keyVendorResponse: Data, options: [String : Any]?) throws -> Data {
        if #available(iOS 10.0, *) {
            return try request.persistentContentKey(fromKeyVendorResponse: keyVendorResponse, options: options)
        } else {
            throw FPSError.persistenceNotSupported
        }
    }
}
