//
//  OTTEntryProvider.swift
//  Pods
//
//  Created by Admin on 13/11/2016.
//
//

import UIKit

class OTTEntryProvider: MediaEntryProvider {

    
    let sessionProvider: SessionProvider
    var mediaId: String
    var type: AssetType
    
    
    public enum error: Error {
        case fileIsEmptyOrNotFound
        case invalidJSON
        case mediaNotFound
        
    }
    
    public init( sessionProvider:SessionProvider, mediaId: String, type:AssetType){
        self.sessionProvider = sessionProvider
        self.mediaId = mediaId
        self.type = type
        
    }
    
    public func loadMedia(callback: @escaping (Result<MediaEntry>) -> Void) {        
        
//        let request = AssetService.get(baseURL: self.sessionProvider.serverURL, ks: self.sessionProvider.ks, assetId: self.mediaId, type:AssetType.media)
//        request?.set(completion: { (Response) in
//            
//            
//        })
        
    }

    
 
}
