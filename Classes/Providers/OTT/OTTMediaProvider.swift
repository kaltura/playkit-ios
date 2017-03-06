//
//  OTTEntryProvider.swift
//  Pods
//
//  Created by Admin on 13/11/2016.
//
//

import UIKit
import SwiftyJSON

@objc public class OTTMediaProvider: NSObject, MediaEntryProvider {
    
    public enum OTTMediaProviderError: Error {
        case invalidInputParams
        case invalidKS
        case fileIsEmptyOrNotFound
        case invalidJSON
        case mediaNotFound
        case currentlyProcessingOtherRequest
        case unableToParseObject
    }
    
    public var sessionProvider: SessionProvider?
    public var mediaId: String?
    public var type: AssetType?
    public var formats: [String]?
    public var executor: RequestExecutor?
    
    public override init() {}
    
    @objc public init(_ sessionProvider: SessionProvider) {
        self.sessionProvider = sessionProvider
    }
    
    @discardableResult
    @nonobjc public func set(sessionProvider: SessionProvider?) -> Self {
        self.sessionProvider = sessionProvider
        return self
    }
    
    @discardableResult
    @nonobjc public func set(mediaId:String?) -> Self {
        self.mediaId = mediaId
        return self
    }
    
    @discardableResult
    @nonobjc public func set(type:AssetType?) -> Self {
        self.type = type
        return self
    }
    
    @discardableResult
    @nonobjc public func set(formats:[String]?) -> Self {
        self.formats = formats
        return self
    }
    
    @discardableResult
    @nonobjc public func set(executor:RequestExecutor?) -> Self {
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
    
    @objc public func loadMedia(callback: @escaping (MediaEntry?, Error?) -> Void) {
        guard let sessionProvider = self.sessionProvider,
            let mediaId = self.mediaId,
            let type = self.type
            else {
                callback(nil, OTTMediaProviderError.invalidInputParams)
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
        
        let loaderParams = LoaderInfo(sessionProvider: sessionProvider, mediaId: mediaId, type: type, formats: formats, executor: executor)
        self.startLoad(loader: loaderParams, callback: callback)
    }
    
    
    public func cancel() {
        
    }
    

    func startLoad(loader: LoaderInfo, callback: @escaping (MediaEntry?, Error?) -> Void) {
        loader.sessionProvider.loadKS { (ks, error) in
            guard let ks = ks else {
                callback(nil, OTTMediaProviderError.invalidKS)
                return
            }
            
            let requestBuilder = OTTAssetService.get(baseURL: loader.sessionProvider.serverURL, ks: ks, assetId: loader.mediaId, type:loader.type)?
                .setOTTBasicParams()
                .set(completion: { (r:Response) in
                    
                    guard let data = r.data else {
                        callback(nil, OTTMediaProviderError.mediaNotFound)
                        return
                    }
                    
                    var object: OTTBaseObject? = nil
                    do {
                        object = try OTTResponseParser.parse(data: data)
                    } catch {
                        callback(nil, error)
                    }
                    
                    if let asset = object as? OTTAsset {
                        
                        let mediaEntry: MediaEntry = MediaEntry(id: asset.id)
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
                        callback(mediaEntry, nil)
                    } else {
                        callback(nil, OTTMediaProviderError.mediaNotFound)
                    }
                })
            if let assetRequest = requestBuilder?.build() {
                loader.executor.send(request: assetRequest)
            }
        }
    }
}

