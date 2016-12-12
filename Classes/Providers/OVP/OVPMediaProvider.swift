//
//  OVPMediaProvider.swift
//  Pods
//
//  Created by Rivka Peleg on 27/11/2016.
//
//

import UIKit

public class OVPMediaProvider: MediaEntryProvider {
    
    
    struct LoaderInfo {
        var sessionProvider: SessionProvider
        var entryId: String
        var uiconfId: Int64?
        var executor: RequestExecutor
        var apiServerURL: String
    }
    
    
    enum Err: Error {
        case invalidParam(paramName:String)
        case invalidKS
        case invalidParams
        case invalidResponse
        case currentlyProcessingOtherRequest
    }
    
    var sessionProvider: SessionProvider?
    var entryId: String?
    var executor: RequestExecutor?
    var uiconfId: Int64?
    var apiServerURL: String?
    
    
    public init(){}
    
    public func set(sessionProvider: SessionProvider?) -> Self{
        self.sessionProvider = sessionProvider
        return self
    }
    
    public func set(entryId: String?) -> Self{
        self.entryId = entryId
        return self
    }

    public func set( executor: RequestExecutor?) -> Self{
        self.executor = executor
        return self
    }

    public func set(uiconfId: Int64?) -> Self{
        self.uiconfId = uiconfId
        return self
    }

    public func set(apiServerURL: String?) -> Self{
        self.apiServerURL = apiServerURL
        return self
    }

    
    
    public func loadMedia(callback: @escaping (Result<MediaEntry>) -> Void){
        
        guard let sessionProvider = self.sessionProvider
        else {
            callback(Result(data: nil, error: Err.invalidParam(paramName: "sessionProvider")))
            return
        }
        
        guard let entryId = self.entryId
            else {
                callback(Result(data: nil, error: Err.invalidParam(paramName: "entryId")))
                return
        }
        
        guard let apiServerURL = self.apiServerURL
            else {
                callback(Result(data: nil, error: Err.invalidParam(paramName: "apiServerURL")))
                return
        }
        
        
        var executor: RequestExecutor = USRExecutor.shared
        if let exe = self.executor {
            executor = exe
        }
        
        
        let loaderInfo = LoaderInfo(sessionProvider: sessionProvider, entryId: entryId, uiconfId: self.uiconfId, executor: executor, apiServerURL: apiServerURL)
        
        self.startLoading(loadInfo: loaderInfo, callback: callback)
        
    }
    
    
    func startLoading(loadInfo:LoaderInfo,callback: @escaping (Result<MediaEntry>) -> Void) -> Void {
        
        loadInfo.sessionProvider.loadKS { (r:Result<String>) in
            
            guard let ks = r.data else {
                callback(Result(data: nil, error: Err.invalidKS))
                return
            }
            
            let listRequest = OVPBaseEntryService.list(baseURL: loadInfo.apiServerURL,
                                                       ks: ks,
                                                       entryID: loadInfo.entryId)
            let getContextDataRequest = OVPBaseEntryService.getContextData(baseURL: loadInfo.apiServerURL,
                                                                           ks: ks,
                                                                           entryID: loadInfo.entryId)
            
            guard let req1 = listRequest,
                let req2 = getContextDataRequest else {
                    callback(Result(data: nil, error: Err.invalidParams))
                    return
            }
            
            let mrb = KalturaMultiRequestBuilder(url: loadInfo.apiServerURL)?
                .add(request: req1).add(request: req2)
                .setOVPBasicParams()
                .set(completion: { (r:Response) in
                    
                    let responses: [OVPBaseObject] = OVPMultiResponseParser.parse(data: r.data)
                    
                    guard responses.count == 2,
                        let mainResponse: OVPBaseObject = responses[0],
                        let contextDataResponse: OVPBaseObject = responses[1],
                        let mainResponseData = mainResponse as? OVPList,
                        let entry = mainResponseData.objects?.last as? OVPEntry,
                        let contextData = contextDataResponse as? OVPEntryContextData,
                        let flavorAssets = contextData.flavorAssets  ,
                        let sources = contextData.sources
                        else{
                            callback(Result(data: nil, error: Err.invalidResponse ))
                            return
                    }
                    
                    let mediaEntry: MediaEntry = MediaEntry(id: entry.id)
                    mediaEntry.duration = entry.duration
                    
                    var mediaSources: [MediaSource] = [MediaSource]()
                    sources.forEach({ (source:OVPSource) in
                        
                        let mediaSource: MediaSource = MediaSource(id: String(source.deliveryProfileId))
                        let sourceBuilder: SourceBuilder = SourceBuilder()
                        let supportedFlavors = self.flavorsByFlavorsParamIds(flavorsIds: source.flavors, flavorAsset: flavorAssets)
                        let flavorsId = self.flavorsId(flavors: supportedFlavors)
                        
                        sourceBuilder.set(baseURL: loadInfo.sessionProvider.serverURL)
                        sourceBuilder.set(ks: ks)
                        sourceBuilder.set(format: source.format)
                        sourceBuilder.set(entryId: loadInfo.entryId)
                        sourceBuilder.set(uiconfId: loadInfo.uiconfId)
                        sourceBuilder.set(flavors: source.flavors)
                        sourceBuilder.set(partnerId: loadInfo.sessionProvider.partnerId)
                        sourceBuilder.set(playSessionId: UUID().uuidString) // insert - session
                        sourceBuilder.set(sourceProtocol: source.protocols?.last)
                        
                        let url = sourceBuilder.build()
                        mediaSource.contentUrl = url
                        let drmData = DRMData(licenseUrl: (source.drm?.last?.licenseURL)!)
                        mediaSource.drmData = drmData
                        mediaSources.append(mediaSource)
                    })
                    mediaEntry.sources = mediaSources
                    callback(Result(data: mediaEntry, error: nil ))
                    
                })
            
            
            if let request = mrb?.build() {
                loadInfo.executor.send(request: request)
                
            }else{
                callback(Result(data: nil, error: Err.invalidParams))
            }
        }

    }
    
    func flavorsByFlavorsParamIds(flavorsIds:[String]?,flavorAsset:[OVPFlavorAsset]) -> [OVPFlavorAsset] {
        
        let flavors = flavorAsset.filter({ (flavorAsset:OVPFlavorAsset) -> Bool in
            
            let isflavorSupported = flavorsIds?.contains(where: { (flavorID:String) -> Bool in
                return String(flavorAsset.paramsId) == flavorID
            })
            
            if let isSupported = isflavorSupported{
                return isSupported
            }else{
                return false
            }
        })
        return flavors
    }
    
    func flavorsId(flavors:[OVPFlavorAsset]) -> [String] {
        
        let flavorsId = flavors.map { (flavor:OVPFlavorAsset) -> String in
            return flavor.id
        }
        
        return flavorsId
    }
    
    
    public func cancel() {
    }
}





