//
//  OTTEntryProvider.swift
//  Pods
//
//  Created by Admin on 13/11/2016.
//
//

import UIKit
import SwiftyJSON

public class OTTEntryProvider: MediaEntryProvider {

    
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
        
        let request = AssetService.get(baseURL: sessionProvider.serverURL, ks: sessionProvider.ks, assetId: self.mediaId, type:self.type)
        request?.set(completion: { (r:Response) in
            let jsonResponse =  JSON(r.data)
            
            
        }).build()
        
        if let assetRequest = request {
            USRExecutor.shared.send(request: assetRequest)
        }
    }

    
 
}
