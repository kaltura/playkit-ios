//
//  OTTEntryProvider.swift
//
//
//  Created by Admin on 13/11/2016.
//
//

import UIKit
import SwiftyJSON



let defaultProtocl = "https"

@objc public class PhoenixMediaProvider: NSObject, MediaEntryProvider {
    
    public enum PhoenixMediaProviderError: Error {
        case invalidInputParams
        case invalidKS
        case fileIsEmptyOrNotFound
        case invalidJSON
        case mediaNotFound
        case currentlyProcessingOtherRequest
        case unableToParseObject
        case noSourcesFound
    }
    
    var sessionProvider: SessionProvider?
    var assetId: String?
    var type: AssetType?
    var formats: [String]?
    var fileIds: [String]?
    var playbackContextType: PlaybackContextType?
    var executor: RequestExecutor?
    var networkProtocol: String?
    
    public override init() { }
    
    @discardableResult
    @nonobjc public func set(sessionProvider: SessionProvider?) -> Self {
        self.sessionProvider = sessionProvider
        return self
    }
    
    @discardableResult
    @nonobjc public func set(assetId:String?) -> Self {
        self.assetId = assetId
        return self
    }
    
    @discardableResult
    @nonobjc public func set(type:AssetType?) -> Self {
        self.type = type
        return self
    }
    
    @discardableResult
    @nonobjc public func set(playbackContextType:PlaybackContextType?) -> Self {
        self.playbackContextType = playbackContextType
        return self
    }

    @discardableResult
    @nonobjc public func set(formats:[String]?) -> Self {
        self.formats = formats
        return self
    }
    
    @discardableResult
    @nonobjc public func set(fileIds:[String]?) -> Self {
        self.fileIds = fileIds
        return self
    }
    
    @discardableResult
    @nonobjc public func set(networkProtocol:String?) -> Self {
        self.networkProtocol = networkProtocol
        return self
    }
    
    @discardableResult
    @nonobjc public func set(executor:RequestExecutor?) -> Self {
        self.executor = executor
        return self
    }
    
    

    
    struct LoaderInfo {
        var sessionProvider: SessionProvider
        var assetId: String
        var assetType: AssetType
        var formats: [String]?
        var fileIds: [String]?
        var playbackContextType: PlaybackContextType
        var networkProtocol: String
        var executor: RequestExecutor
        
    }
    
    @objc public func loadMedia(callback: @escaping (MediaEntry?, Error?) -> Void) {
        guard let sessionProvider = self.sessionProvider,
            let assetId = self.assetId,
            let type = self.type,
            let contextType = self.playbackContextType
            else {
                callback(nil, PhoenixMediaProviderError.invalidInputParams)
                return
        }
        
        let pr = self.networkProtocol ?? defaultProtocl
        var executor: RequestExecutor = USRExecutor.shared
        if let exe = self.executor{
            executor = exe
        }
        
        let loaderParams = LoaderInfo(sessionProvider: sessionProvider, assetId: assetId, assetType: type, formats: self.formats, fileIds: self.fileIds, playbackContextType: contextType, networkProtocol:pr, executor: executor)
        
        self.startLoad(loaderInfo: loaderParams, callback: callback)
    }
    
    
    public func cancel() {
        
    }
    

    
    func loaderRequestBuilder(ks:String?, loaderInfo:LoaderInfo) -> KalturaRequestBuilder? {
        
       let playbackContextOptions = PlaybackContextOptions(playbackContextType: loaderInfo.playbackContextType, protocls: [loaderInfo.networkProtocol], assetFileIds: loaderInfo.fileIds)
        
        if let token = ks {
            
            let playbackContextRequest = OTTAssetService.getPlaybackContext(baseURL:loaderInfo.sessionProvider.serverURL, ks: token, assetId: loaderInfo.assetId , type: loaderInfo.assetType, playbackContextOptions: playbackContextOptions )
            return playbackContextRequest
        }else{
            
            let anonymouseLoginRequest = OTTUserService.anonymousLogin(baseURL: loaderInfo.sessionProvider.serverURL, partnerId: loaderInfo.sessionProvider.partnerId)
            let ks = "{1:result:ks}"
            let playbackContextRequest = OTTAssetService.getPlaybackContext(baseURL:loaderInfo.sessionProvider.serverURL, ks: ks, assetId: loaderInfo.assetId , type: loaderInfo.assetType, playbackContextOptions: playbackContextOptions )
            
            guard let req1 = anonymouseLoginRequest, let req2 = playbackContextRequest else {
                return nil
            }
            
            let multiRquest = KalturaMultiRequestBuilder(url: loaderInfo.sessionProvider.serverURL)?.setOTTBasicParams()
            multiRquest?.add(request: req1).add(request: req2)
            return multiRquest
            
            
        }
        
     
    }
    
    func startLoad(loaderInfo: LoaderInfo, callback: @escaping (MediaEntry?, Error?) -> Void) {
        loaderInfo.sessionProvider.loadKS { (ks, error) in
            
            guard let requestBuilder: KalturaRequestBuilder =  self.loaderRequestBuilder( ks: ks, loaderInfo: loaderInfo) else {
                callback(nil, PhoenixMediaProviderError.invalidInputParams)
                return
            }
            
            let isMultiRequest = requestBuilder is KalturaMultiRequestBuilder
            
            let request = requestBuilder.set(completion: { (response:Response) in
                
                var playbackContext: OTTPlaybackContext? = nil
                do {
                    if (isMultiRequest){
                        playbackContext =  try OTTMultiResponseParser.parse(data: response.data).last as? OTTPlaybackContext
                    } else{
                        playbackContext =  try OTTResponseParser.parse(data: response.data) as? OTTPlaybackContext
                    }
                    
                }catch {
                    callback(nil, PhoenixMediaProviderError.unableToParseObject)
                }
                
                if let context = playbackContext {
                    let media = self.createMediaEntry(loaderInfo: loaderInfo, context: context)
                    if let sources = media.sources, sources.count > 0 {
                       callback(media, nil)
                    }else{
                        callback(nil, PhoenixMediaProviderError.noSourcesFound)
                    }
                    
                }
            }).build()
            
            
            loaderInfo.executor.send(request: request)
        }
    }
    
    
    
    func sortedAndFilterSources(by fileIds:[String]?, or fileFormats:[String]?, sources:[OTTPlaybackSource]) -> [OTTPlaybackSource] {
        
        let orderedSources = sources.filter({ (source:OTTPlaybackSource) -> Bool in
             if let formats = fileFormats  {
                return formats.contains(source.type)
             }else if let  fileIds = fileIds {
                return fileIds.contains("\(source.id)")
             }else{
                return true
            }
        })
        .sorted { (source1:OTTPlaybackSource, source2:OTTPlaybackSource) -> Bool in
            
            if let formats = fileFormats  {
                let index1 = formats.index(of: source1.type) ?? 0
                let index2 = formats.index(of: source2.type) ?? 0
                return index1 < index2
            }else if let  fileIds = fileIds {
                
                let index1 = fileIds.index(of: "\(source1.id)") ?? 0
                let index2 = fileIds.index(of: "\(source2.id)") ?? 0
                return index1 < index2
            }else{
                return false
            }
        }
        
        return orderedSources
        
        
    }
    
    func createMediaEntry(loaderInfo: LoaderInfo, context: OTTPlaybackContext) -> MediaEntry {
        
        let mediaEntry = MediaEntry(id: loaderInfo.assetId)
        let sortedSources = self.sortedAndFilterSources(by: loaderInfo.fileIds, or: loaderInfo.formats, sources: context.sources)
        
        var maxDuration: Float = 0.0
        let mediaSources =  sortedSources.flatMap { (source:OTTPlaybackSource) -> MediaSource? in
            
            let format = FormatsHelper.getMediaFormat(format: source.format, hasDrm: source.drm != nil)
            guard  FormatsHelper.supportedFormats.contains(format) else {
                return nil
            }
            
            var drm: [DRMParams]? = nil
            if let drmData = source.drm, drmData.count > 0 {
                drm = drmData.flatMap({ (drmData:OTTDrmData) -> DRMParams? in
                    
                    let scheme = self.convertScheme(scheme: drmData.scheme)
                    guard FormatsHelper.supportedSchemes.contains(scheme) else {
                        return nil
                    }
                    
                    switch scheme {
                    case .fairplay:
                        // if the scheme is type fair play and there is no certificate or license URL
                        guard let certifictae = drmData.certificate
                            else { return nil }
                        return FairPlayDRMParams(licenseUri: drmData.licenseURL, scheme: scheme, base64EncodedCertificate: certifictae)
                    default:
                        return DRMParams(licenseUri: drmData.licenseURL, scheme: scheme)
                    }
               })
                
                // checking if the source is supported with his drm data, cause if the source has drm data but from some reason the mapped drm data is empty the source is not playable
                guard let mappedDrmData = drm , mappedDrmData.count > 0  else {
                    return nil
                }
            }
            
            
            
            let mediaSource = MediaSource(id: "\(source.id)")
            mediaSource.contentUrl = source.url
            mediaSource.mediaFormat = format
            mediaSource.drmData = drm
            
            maxDuration = max(maxDuration, source.duration)
            return mediaSource
            
        }
        
        mediaEntry.sources = mediaSources
        mediaEntry.duration = TimeInterval(maxDuration)
        
        
        return mediaEntry
        
        
        
        
        
       
    }
    
    func convertScheme(scheme: String) -> DRMParams.Scheme {
            switch (scheme) {
            case "WIDEVINE_CENC":
                return .widevineCenc
            case "PLAYREADY_CENC":
                return .playreadyCenc
            case "WIDEVINE":
                return .widevineClassic
            case "FAIRPLAY":
                return .fairplay
            default:
                return .unknown;
            }
    }
    
    
}

