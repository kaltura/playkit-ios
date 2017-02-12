//
//  SimpleOVPMediaProvider.swift
//  Pods
//
//  Created by Noam Tamim on 09/02/2017.
//
//

import UIKit

public class SimpleOVPMediaProvider: MediaEntryProvider {
    
    public let serverURL: String
    public let partnerId: Int64
    public var ks: String?
    public var entryId: String?
    
    private var currentProvider: MediaEntryProvider?
    
    public init(serverURL: String, partnerId: Int64, ks: String?) {
        self.serverURL = serverURL
        self.partnerId = partnerId
        self.ks = ks
    }
    
    @discardableResult
    public func setEntryId(_ entryId: String) -> Self {
        self.entryId = entryId
        return self
    }
    
    public func loadMedia(callback: @escaping (Result<MediaEntry>) -> Void) {
        self.cancel()
        
        if let ks = self.ks {
            self.loadMedia(sessionProvider: SimpleSessionProvider(serverURL: serverURL, partnerId: partnerId, ks: ks), callback: callback)
        } else {
            let sessionProvider = OVPSessionManager(serverURL: serverURL, partnerId: partnerId)
            sessionProvider.startAnonymouseSession(completion: { (error: Error?) in
                self.loadMedia(sessionProvider: sessionProvider, callback: callback)
            })
        }
    }
    
    public func cancel() {
        currentProvider?.cancel()
    }
    
    private class SimpleSessionProvider: SessionProvider {
        let serverURL: String
        let partnerId: Int64
        let ks: String
        init(serverURL: String, partnerId: Int64, ks: String) {
            self.serverURL = serverURL
            self.partnerId = partnerId
            self.ks = ks
        }
        
        func loadKS(completion: @escaping (Result<String>) -> Void) {
            completion(Result(data: ks))
        }
    }
    
    private func loadMedia(sessionProvider: SessionProvider, callback: @escaping (Result<MediaEntry>) -> Void) {
        let mediaProvider = OVPMediaProvider()
            .set(entryId: self.entryId)
            .set(sessionProvider: sessionProvider)
        mediaProvider.loadMedia(callback: callback)
        
        self.currentProvider = mediaProvider
    }

}
