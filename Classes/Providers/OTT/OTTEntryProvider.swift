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
    var formats: [String]?
    
    
    public enum ProviderError: Error {
        case fileIsEmptyOrNotFound
        case invalidJSON
        case mediaNotFound
        
        
    }
    
    public init(sessionProvider:SessionProvider, mediaId: String, type:AssetType,formats: [String]){
        self.sessionProvider = sessionProvider
        self.mediaId = mediaId
        self.type = type
        self.formats = formats
    }
    
    public func loadMedia(callback: @escaping (Result<MediaEntry>) -> Void) {
        
        //self.sessionProvider.loadKS { (r:Result<String>) in
            
            
            let request = OTTAssetService.get(baseURL: sessionProvider.serverURL, ks: "ks", assetId: self.mediaId, type:self.type)
            request?.set(completion: { (r:Response) in
                
                guard let data = r.data else {
                    callback(Result(data: nil, error: ProviderError.mediaNotFound))
                    return
                }
                
                let jsonResponse =  JSON(data: data)
                
                if let assetResponse: OTTGetAssetResponse = OTTGetAssetResponse(json:jsonResponse.object){
                    
                    if let asset = assetResponse.asset {
                        
                        let mediaEntry: MediaEntry = MediaEntry(id: asset.id)
                        if let files = asset.files, let requestedFormats = self.formats {
                            
                            var sources = [MediaSource]()
                            for  file in files {
                                if let fileFormat = file.type{
                                    if requestedFormats.contains(fileFormat) == true {
                                        let source: MediaSource = MediaSource(id: file.id)
                                        source.contentUrl = file.url
                                        sources.append(source)
                                    }
                                }
                            }
                            
                            if sources.count > 0 {
                                mediaEntry.sources = sources
                            }
                        }
                        
                        callback(Result(data: mediaEntry, error: nil))
                    }else{
                        callback(Result(data: nil, error: ProviderError.mediaNotFound))
                    }
                }else{
                    callback(Result(data: nil, error: ProviderError.mediaNotFound))
                }
            }).build()
            
            if let assetRequest = request {
                USRExecutor.shared.send(request: assetRequest)
            }
            
    }
}


    

