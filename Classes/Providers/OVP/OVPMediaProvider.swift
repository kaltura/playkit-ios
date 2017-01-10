//
//  OVPMediaProvider.swift
//  Pods
//
//  Created by Rivka Peleg on 27/11/2016.
//
//

import UIKit
import SwiftyXMLParser

public class OVPMediaProvider: MediaEntryProvider {
   

    
    //This object is initiate at the begning of loadMedia methos and contain all neccessery info to load.
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
    
    private var sessionProvider: SessionProvider?
    private var entryId: String?
    private var executor: RequestExecutor?
    private var uiconfId: Int64?
    
    
    public init(){}
    /**
     session provider - which resposible for the ks, prtner id, and base server url
     */
    @discardableResult
    public func set(sessionProvider: SessionProvider?) -> Self{
        self.sessionProvider = sessionProvider
        return self
    }
    
    /**
     entryId - entry which we need to play
     */
    @discardableResult
    public func set(entryId: String?) -> Self{
        self.entryId = entryId
        return self
    }
    
    /**
     executor - which resposible for the network, it can be set to
     */
    @discardableResult
    public func set( executor: RequestExecutor?) -> Self{
        self.executor = executor
        return self
    }
    
    /**
     uiconfId - UI Configuration id
     */
    @discardableResult
    public func set(uiconfId: Int64?) -> Self{
        self.uiconfId = uiconfId
        return self
    }
    
    
    
    public func loadMedia(callback: @escaping (Result<MediaEntry>) -> Void){
        
        // session provider is required in order to have the base url and the partner id
        guard let sessionProvider = self.sessionProvider
            else {
                callback(Result(data: nil, error: Err.invalidParam(paramName: "sessionProvider")))
                PKLog.debug("Proivder must have session info")
                return
        }
        
        // entryId is requierd
        guard let entryId = self.entryId
            else {
                callback(Result(data: nil, error: Err.invalidParam(paramName: "entryId")))
                PKLog.debug("Proivder must have entryId")
                return
        }
        
        // if there is not executor we are using the default one
        var executor: RequestExecutor = USRExecutor.shared
        if let exe = self.executor {
            executor = exe
        }
        
        //building the loader info which contain all required fields
        let loaderInfo = LoaderInfo(sessionProvider: sessionProvider, entryId: entryId, uiconfId: self.uiconfId, executor: executor, apiServerURL: sessionProvider.serverURL + "/api_v3")
        
        self.startLoading(loadInfo: loaderInfo, callback: callback)
        
    }
    
    
    func startLoading(loadInfo:LoaderInfo,callback: @escaping (Result<MediaEntry>) -> Void) -> Void {
        
        loadInfo.sessionProvider.loadKS { (ksResponse:Result<String>) in
            
            let mrb = KalturaMultiRequestBuilder(url: loadInfo.apiServerURL)?.setOVPBasicParams()
            var ks: String? = nil
            
            // checking if we got ks from the session, otherwise we should work as anonymous
            if let data = ksResponse.data, data.isEmpty == false {
                ks = data
            }
            else{
                // Adding "startWidgetSession" request in case we don't have ks
                let loginRequestBuilder = OVPSessionService.startWidgetSession(baseURL: loadInfo.apiServerURL,
                                                                               partnerId: loadInfo.sessionProvider.partnerId)
                if let req = loginRequestBuilder {
                    mrb?.add(request: req)
                    // changing the ks to this format in order to use it as a multi request ( forward from the first response )
                    ks = "{1:result:ks}"
                }
            }
            
            // if we don't have forwared token and not real token we can't continue
            guard let token = ks else {
                callback(Result(data: nil, error: Err.invalidKS))
                PKLog.debug("can't find ks and can't request as anonymous ks (WidgetSession) ")
                return
            }
            
            
            // Request for Entry data
            let listRequest = OVPBaseEntryService.list(baseURL: loadInfo.apiServerURL,
                                                       ks: token,
                                                       entryID: loadInfo.entryId)
            
            // Request for Entry playback data in order to build sources to play
            let getPlaybackContext =  OVPBaseEntryService.getPlaybackContext(baseURL: loadInfo.apiServerURL,
                                                                             ks: token,
                                                                             entryID: loadInfo.entryId)
            let metadataRequest = OVPBaseEntryService.metadata(baseURL: loadInfo.apiServerURL, ks: token, entryID: loadInfo.entryId)
            
            guard let req1 = listRequest,
                let req2 = getPlaybackContext, let req3 = metadataRequest else {
                    callback(Result(data: nil, error: Err.invalidParams))
                    return
            }
            
            //Building the multi request
            mrb?.add(request: req1)
                .add(request: req2)
                .add(request: req3)
                .set(completion: { (dataResponse:Response) in
                    
                    let responses: [OVPBaseObject] = OVPMultiResponseParser.parse(data: dataResponse.data)
                    
                    // At leat we need to get response of Entry and Playback, on anonymous we will have additional startWidgetSession call
                    guard responses.count >= 2
                        else {
                            callback(Result(data: nil, error: Err.invalidResponse ))
                            PKLog.debug("didn't get response for all requests")
                            return
                    }
                    
                    let metaData:OVPBaseObject = responses[responses.count-1]
                    let contextDataResponse: OVPBaseObject = responses[responses.count-2]
                    let mainResponse: OVPBaseObject = responses[responses.count-3]
                    
                    guard
                        let mainResponseData = mainResponse as? OVPList,
                        let entry = mainResponseData.objects?.last as? OVPEntry,
                        let contextData = contextDataResponse as? OVPPlaybackContext,
                        let sources = contextData.sources,
                        let metadataListObject = metaData as? OVPList,
                        let metadataList = metadataListObject.objects as? [OVPMetadata]
                        else{
                            callback(Result(data: nil, error: Err.invalidResponse ))
                            PKLog.debug("Response is not containing Entry info or playback data")
                            return
                    }
                    
                    
                    var mediaSources: [MediaSource] = [MediaSource]()
                    sources.forEach({ (source:OVPSource) in
                        
                        //detecting the source type
                        let sourceType = self.getSourceType(source: source)
                        //If source type is not supported source will not be created
                        guard sourceType != .unknown else { return }
                        
                        var ksForURL = ksResponse.data
                        
                        // retrieving the ks from the response of StartWidgetSession
                        if responses.count > 2 {
                            if let widgetSession = responses[0] as? OVPStartWidgetSessionResponse {
                                ksForURL = widgetSession.ks
                            }
                        }

                        var playURL: URL? = self.playbackURL(loadInfo: loadInfo, source: source, ks: ksForURL)
                        guard let url = playURL else {
                            PKLog.warning("failed to create play url from source, discarding source:\(entry.id),\(source.deliveryProfileId), \(source.format)")
                            return
                        }
                        
                        let drmData = self.buildDRMData(drm: source.drm)
                        
                        //creating media source with the above data
                        let mediaSource: MediaSource = MediaSource(id: entry.id + "_" + String(source.deliveryProfileId))
                        mediaSource.drmData = drmData
                        mediaSource.contentUrl = url
                        mediaSources.append(mediaSource)
                    })
                    
                    var metaDataItems = [String: String]()
                    
                    for meta in metadataList {
                        do{
                            let xml = try! XML.parse(meta.xml!)
                            if let allNodes = xml["metadata"].all{
                                for element in allNodes {
                                    for dataElement in element.childElements {
                                        metaDataItems[dataElement.name] = dataElement.text
                                    }
                                }
                            }
                        }catch{
                          PKLog.warning("Error occur while trying to parse metadata XML")
                        }
                    }
                    
                    
                    //creating media entry with the above sources
                    let mediaEntry: MediaEntry = MediaEntry(id: entry.id)
                    mediaEntry.duration = entry.duration
                    mediaEntry.sources = mediaSources
                    mediaEntry.metadata = metaDataItems
                    callback(Result(data: mediaEntry, error: nil ))
                })
            
            
            if let request = mrb?.build() {
                loadInfo.executor.send(request: request)
                
            }else{
                callback(Result(data: nil, error: Err.invalidParams))
            }
        }
        
    }
    
    
    // This method decding the source type base on scheck and drm data
    private func getSourceType(source:OVPSource) -> MediaSource.SourceType {
        
        if let format = source.format {
            switch format {
            case "applehttp":
                if source.drm == nil {
                    return MediaSource.SourceType.hls_clear
                }else{
                    return MediaSource.SourceType.hls_fair_play
                }
            case "url":
                if source.drm == nil {
                    return MediaSource.SourceType.mp4_clear
                }else{
                    return MediaSource.SourceType.wvm_wideVine
                }
            default:
                return MediaSource.SourceType.unknown
            }
        }
        
        return MediaSource.SourceType.unknown
        
    }
    
    
    // Creating the drm data based on scheme
    private func buildDRMData(drm:[OVPDRM]?) -> [DRMData]? {
        
        let drmData = drm?.flatMap({ (drm:OVPDRM) -> DRMData? in
            
            guard let scheme = drm.scheme else {
                return nil
            }
            
            var drmData: DRMData? = nil
            switch scheme {
            case "fairplay.FAIRPLAY":
                guard let certifictae = drm.certificate,
                    let licenseURL = drm.licenseURL
                    // if the scheme is type fair play and there is no certificate or license URL
                    else { return nil }
                drmData = FairPlayDRMData(licenseUri: licenseURL, base64EncodedCertificate: certifictae)
            default:
                drmData = DRMData(licenseUri: drm.licenseURL)
                
            }
            
            return drmData
            
        })
        
        return drmData
        
    }
    
    // building the url with the SourceBuilder class
    private func playbackURL(loadInfo:LoaderInfo,source:OVPSource,ks:String?) -> URL? {
        
        let sourceType = self.getSourceType(source: source)
        var playURL: URL? = nil
        if let flavors =  source.flavors,
            flavors.count > 0 {
            
            let sourceBuilder: SourceBuilder = SourceBuilder()
                .set(baseURL: loadInfo.sessionProvider.serverURL)
                .set(format: source.format)
                .set(entryId: loadInfo.entryId)
                .set(uiconfId: loadInfo.uiconfId)
                .set(flavors: source.flavors)
                .set(partnerId: loadInfo.sessionProvider.partnerId)
                .set(playSessionId: UUID().uuidString)
                .set(sourceProtocol: source.protocols?.last)
                .set(fileExtension: sourceType.fileExtension)
                .set(ks: ks)
            playURL = sourceBuilder.build()
        }
        else{
            playURL = source.url
        }
        
        
        return playURL

    }
    
    public func cancel(){
        
    }
}







