//
//  OVPMediaProvider.swift
//  Pods
//
//  Created by Rivka Peleg on 27/11/2016.
//
//

import UIKit

public class OVPMediaProvider: MediaEntryProvider {
    
    
    enum error: Error {
        case invalidKS
        case invalidParams
        case invalidResponse
        case currentlyProcessingOtherRequest
  }
    
    
    
    private var currentRequest: Request? = nil
    
    var sessionProvider: SessionProvider
    var entryId: String
    var executor: RequestExecutor
    var uiconfId: Int64?
    var apiServerURL: String
    
    
    public init (sessionProvider:SessionProvider, entryId: String,uiconfId:Int64?, executor: RequestExecutor?){
        
        self.sessionProvider = sessionProvider
        self.entryId = entryId
        self.uiconfId = uiconfId
        self.apiServerURL = sessionProvider.serverURL.appending("/api_v3")
        
        if let exe = executor {
            self.executor = exe
        }else{
            self.executor = USRExecutor.shared
        }
        
    }
    
    
    public func loadMedia(callback: @escaping (Result<MediaEntry>) -> Void){
        
        if self.currentRequest != nil{
            callback(Result(data: nil, error: error.currentlyProcessingOtherRequest ))
            return
        }
        
        self.sessionProvider.loadKS { (r:Result<String>) in
            
            if let ks = r.data{
                let listRequest = OVPBaseEntryService.list(baseURL: self.apiServerURL, ks: ks, entryID: self.entryId)
                let getContextDataRequest = OVPBaseEntryService.getContextData(baseURL: self.apiServerURL, ks: ks, entryID: self.entryId)
                
                
                if let req1 = listRequest, let req2 = getContextDataRequest{
                    
                    let mrb = KalturaMultiRequestBuilder(url: self.apiServerURL)?.add(request: req1).add(request: req2).setOVPBasicParams().set(completion: { (r:Response) in
                        
                        self.currentRequest = nil
                        let responses: [OVPBaseObject] = OVPMultiResponseParser.parse(data: r.data)
                        
                        if (responses.count == 2){
                            
                            let mainResponse: OVPBaseObject = responses[0]
                            let contextDataResponse: OVPBaseObject = responses[1]
                            
                            guard let mainResponseData = mainResponse as? OVPList, let entry = mainResponseData.objects?.last as? OVPEntry, let contextData = contextDataResponse as? OVPEntryContextData, let flavorAssets = contextData.flavorAssets  ,let sources = contextData.sources else{
                                callback(Result(data: nil, error: error.invalidResponse ))
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
                                
                                sourceBuilder.set(baseURL: self.sessionProvider.serverURL)
                                sourceBuilder.set(ks: ks)
                                sourceBuilder.set(format: source.format)
                                sourceBuilder.set(entryId: self.entryId)
                                sourceBuilder.set(uiconfId: self.uiconfId)
                                sourceBuilder.set(flavors: source.flavors)
                                sourceBuilder.set(partnerId: self.sessionProvider.partnerId)
                                sourceBuilder.set(playSessionId: UUID().uuidString) // insert - session
                                sourceBuilder.set(sourceProtocol: source.protocols?.last)
                                
                                let url = sourceBuilder.build()
                                mediaSource.contentUrl = url
                                let drmData = DRMData()
                                drmData.licenseURL = source.drm?.last?.licenseURL
                                mediaSource.drmData = drmData
                                mediaSources.append(mediaSource)
                            })
                            mediaEntry.sources = mediaSources
                            callback(Result(data: mediaEntry, error: nil ))
                        }else{
                            callback(Result(data: nil, error: error.invalidResponse ))
                        }
                    })
                        .build()
                    
                    if let request = mrb {
                        self.currentRequest = request
                        self.executor.send(request: request)
                        
                    }else{
                        callback(Result(data: nil, error: error.invalidParams))
                    }
                }else{
                    callback(Result(data: nil, error: error.invalidParams))
                }
                
            }else{
                callback(Result(data: nil, error: error.invalidKS))
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
        if let currentRequest = self.currentRequest {
            self.executor.cancel(request: currentRequest)
        }
    }
    
    
}





