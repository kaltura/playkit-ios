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
    var executor: RequestExecutor
    
    
    public enum ProviderError: Error {
        case invalidKS
        case fileIsEmptyOrNotFound
        case invalidJSON
        case mediaNotFound
        case currentlyProcessingOtherRequest
        case unableToParseObject
    }
    
    public init(sessionProvider:SessionProvider, mediaId: String, type:AssetType,formats: [String],executor:RequestExecutor?){
        self.sessionProvider = sessionProvider
        self.mediaId = mediaId
        self.type = type
        self.formats = formats
        
        if let exe = executor {
            self.executor = exe
        }else{
            self.executor = USRExecutor.shared
        }
    }
    
    
    public func loadMedia(callback: @escaping (Result<MediaEntry>) -> Void) {
        
        //        if self.currentRequest != nil{
        //            callback(Result(data: nil, error: ProviderError.currentlyProcessingOtherRequest ))
        //            return
        //        }
        
        self.sessionProvider.loadKS { (r:Result<String>) in
            
            guard let ks = r.data else {
                callback(Result(data: nil, error: ProviderError.invalidKS))
                return
            }
            
            let requestBuilder = OTTAssetService.get(baseURL: self.sessionProvider.serverURL, ks: ks, assetId: self.mediaId, type:self.type)?.setOTTBasicParams()
            requestBuilder?.set(completion: { (r:Response) in
                
                guard let data = r.data else {
                    callback(Result(data: nil, error: ProviderError.mediaNotFound))
                    return
                }
                
                let object: OTTBaseObject? = nil
                do {
                    let object = try OTTResponseParser.parse(data: data)
                }catch{
                    callback(Result(data: nil, error: error))
                }
                
                if let asset = object as? OTTAsset {
                    
                    let mediaEntry: MediaEntry = MediaEntry(id: asset.id)
                    let licensedLinkRequests: [KalturaRequestBuilder] = [KalturaRequestBuilder]()
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
                
            })
            
            if let assetRequest = requestBuilder?.build() {
                self.executor.send(request: assetRequest)
            }
        }
    }
    
    public func cancel() {
        
    }
    
    
}
