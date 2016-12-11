//
//  OTTEntryProvider.swift
//  Pods
//
//  Created by Admin on 13/11/2016.
//
//

import UIKit
import SwiftyJSON

public class OTTMediaProvider: MediaEntryProvider {
    
    
    var sessionProvider: SessionProvider?
    var mediaId: String?
    var type: AssetType?
    var formats: [String]?
    var executor: RequestExecutor?
    
    public enum Err: Error {
        case invalidInputParams
        case invalidKS
        case fileIsEmptyOrNotFound
        case invalidJSON
        case mediaNotFound
        case currentlyProcessingOtherRequest
        case unableToParseObject
    }
    
    
    public init(){
        
    }
    
    public func set(sessionProvider:SessionProvider?) -> Self {
        self.sessionProvider = sessionProvider
        return self
    }
    
    public func set(mediaId:String?) -> Self {
        self.mediaId = mediaId
        return self
    }
    
    public func set(type:AssetType?) -> Self {
        self.type = type
        return self
    }
    
    public func set(formats:[String]?) -> Self {
        self.formats = formats
        return self
    }
    public func set(executor:RequestExecutor?) -> Self {
        self.executor = executor
        return self
    }
    
    
    struct LoaderInfo {
        
        var sessionProvider: SessionProvider
        var mediaId: String
        var type: AssetType
        var formats: [String]
        var executor: RequestExecutor
        
    }
    
    public func loadMedia(callback: @escaping (Result<MediaEntry>) -> Void) {
        
        
        guard let sessionProvider = self.sessionProvider,
            let mediaId = self.mediaId,
            let type = self.type
            else {
                callback(Result(data: nil, error: Err.invalidInputParams))
                return
        }
        
        var executor: RequestExecutor = USRExecutor.shared
        var formats: [String] = []
        if let exe = self.executor{
            executor = exe
        }
        
        if let fmts = self.formats {
            formats = fmts
        }
        
        var loaderParams = LoaderInfo(sessionProvider: sessionProvider, mediaId: mediaId, type: type, formats: formats, executor: executor)
        self.startLoad(loader: loaderParams, callback: callback)
    }
    
    
    public func cancel() {
        
    }
    
    func startLoad(loader:LoaderInfo,callback: @escaping (Result<MediaEntry>) -> Void) {
        loader.sessionProvider.loadKS { (r:Result<String>) in
            
            guard let ks = r.data else {
                callback(Result(data: nil, error: Err.invalidKS))
                return
            }
            
            let requestBuilder = OTTAssetService.get(baseURL: loader.sessionProvider.serverURL, ks: ks, assetId: loader.mediaId, type:loader.type)?
                .setOTTBasicParams()
                .set(completion: { (r:Response) in
                    
                    guard let data = r.data else {
                        callback(Result(data: nil, error: Err.mediaNotFound))
                        return
                    }
                    
                    var object: OTTBaseObject? = nil
                    do {
                        object = try OTTResponseParser.parse(data: data)
                    }catch{
                        callback(Result(data: nil, error: error))
                    }
                    
                    if let asset = object as? OTTAsset {
                        
                        let mediaEntry: MediaEntry = MediaEntry(id: asset.id)
                        let licensedLinkRequests: [KalturaRequestBuilder] = [KalturaRequestBuilder]()
                        if let files = asset.files {
                            
                            var sources = [MediaSource]()
                            for  file in files {
                                if let fileFormat = file.type{
                                    if loader.formats.contains(fileFormat) == true {
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
                        callback(Result(data: nil, error: Err.mediaNotFound))
                    }
                    
                })
            
            if let assetRequest = requestBuilder?.build() {
                loader.executor.send(request: assetRequest)
            }
        }
        
    }
}

