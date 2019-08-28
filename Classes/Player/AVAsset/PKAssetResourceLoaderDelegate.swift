//
//  PKAssetResourceLoaderDelegate.swift
//  PlayKit
//
//  Created by Nilit Danan on 8/28/19.
//

import Foundation
import AVFoundation

class PKAssetResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate {
    
    var delegates: [String : AVAssetResourceLoaderDelegate] = [:]
    
    func setDelegate(_ delegate : AVAssetResourceLoaderDelegate, forScheme scheme: String) {
        delegates[scheme] = delegate
    }

    // MARK: - AVAssetResourceLoaderDelegate
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        
        PKLog.verbose("\(#function) was called in PKAssetResourceLoaderDelegate with loadingRequest: \(loadingRequest)")
        
        guard let scheme = loadingRequest.request.url?.scheme else { return false }
        guard let delegate = delegates[scheme] else { return false }
        
        return delegate.resourceLoader?(resourceLoader, shouldWaitForLoadingOfRequestedResource: loadingRequest) ?? false
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForRenewalOfRequestedResource renewalRequest: AVAssetResourceRenewalRequest) -> Bool {
        
        PKLog.verbose("\(#function) was called in PKAssetResourceLoaderDelegate with renewalRequest: \(renewalRequest)")
        
        guard let scheme = renewalRequest.request.url?.scheme else { return false }
        guard let delegate = delegates[scheme] else { return false }
        
        return delegate.resourceLoader?(resourceLoader, shouldWaitForRenewalOfRequestedResource: renewalRequest) ?? false
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        
        PKLog.verbose("\(#function) was called in PKAssetResourceLoaderDelegate with loadingRequest: \(loadingRequest)")
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForResponseTo authenticationChallenge: URLAuthenticationChallenge) -> Bool {
        
        PKLog.verbose("\(#function) was called in PKAssetResourceLoaderDelegate with authenticationChallenge: \(authenticationChallenge)")
        return false
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel authenticationChallenge: URLAuthenticationChallenge) {
        
        PKLog.verbose("\(#function) was called in PKAssetResourceLoaderDelegate with authenticationChallenge: \(authenticationChallenge)")
    }
}
