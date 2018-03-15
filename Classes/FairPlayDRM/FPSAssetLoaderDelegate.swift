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



class FPSAssetLoaderDelegate: NSObject {
    
    /// The URL scheme for FPS content.
    static let customScheme = "skd"
    
    /// Error domain for errors being thrown in the process of getting a CKC.
    static let errorDomain = "AssetLoaderDelegate"
    
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
    
    static func configureRemotePlay(asset: AVURLAsset, drmData: FairPlayDRMParams) -> FPSAssetLoaderDelegate {
        let delegate = FPSAssetLoaderDelegate.init(drmData: drmData)
        
        asset.resourceLoader.setDelegate(delegate, queue: resourceLoadingRequestQueue)
        
        return delegate
    }
    
    @available(iOS 10.0, *)
    static func configureDownload(asset: AVURLAsset, drmData: FairPlayDRMParams, storage: LocalDataStore) -> FPSAssetLoaderDelegate {
        let delegate = FPSAssetLoaderDelegate.init(drmData: drmData, storage: storage)
        
        asset.resourceLoader.setDelegate(delegate, queue: resourceLoadingRequestQueue)
        asset.resourceLoader.preloadsEligibleContentKeys = true
        
        return delegate
    }
    
    @available(iOS 10.0, *)
    static func configureLocalPlay(asset: AVURLAsset, storage: LocalDataStore) -> FPSAssetLoaderDelegate {
        let delegate = FPSAssetLoaderDelegate.init(storage: storage)
        
        asset.resourceLoader.setDelegate(delegate, queue: resourceLoadingRequestQueue)
        asset.resourceLoader.preloadsEligibleContentKeys = true
        
        return delegate
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
                let error = NSError(domain: FPSAssetLoaderDelegate.errorDomain, code: -1, userInfo: nil)
                resourceLoadingRequest.finishLoading(with: error)
                self.done?(error)
                return
            }
        }
        
        var helper: FPSLicenseHelper
        if let fpsParams = self.drmData, self.storage != nil {
            helper = try! FPSLicenseHelper(assetId: assetIDString, params: fpsParams, shouldPersist: shouldPersist, forceDownload: true)
        } else {
            helper = FPSLicenseHelper(assetId: assetIDString)
        }
        
        try! helper.fetchLicense(resourceLoadingRequest: resourceLoadingRequest, usePersistence: shouldPersist) { (error) in
            // TODO
        }
    }

    func shouldLoadOrRenewRequestedResource(resourceLoadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        
        guard let url = resourceLoadingRequest.request.url else {
            return false
        }
        
        // AssetLoaderDelegate only should handle FPS Content Key requests.
        if url.scheme != FPSAssetLoaderDelegate.customScheme {
            return false
        }
        
        FPSAssetLoaderDelegate.resourceLoadingRequestQueue.async {
            self.prepareAndSendContentKeyRequest(resourceLoadingRequest: resourceLoadingRequest)
        }
        
        return true
    }
}

//MARK:- AVAssetResourceLoaderDelegate protocol methods extension
extension FPSAssetLoaderDelegate: AVAssetResourceLoaderDelegate {
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        
        PKLog.trace("\(#function) was called in AssetLoaderDelegate with loadingRequest: \(loadingRequest)")
        
        return shouldLoadOrRenewRequestedResource(resourceLoadingRequest: loadingRequest)
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForRenewalOfRequestedResource renewalRequest: AVAssetResourceRenewalRequest) -> Bool {
        
        PKLog.trace("\(#function) was called in AssetLoaderDelegate with renewalRequest: \(renewalRequest)")
        
        return shouldLoadOrRenewRequestedResource(resourceLoadingRequest: renewalRequest)
    }
    
}
