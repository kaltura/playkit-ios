// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import UIKit
import SwiftyXMLParser
import KalturaNetKit

@objc public class OVPMediaProvider: NSObject, MediaEntryProvider {

    //This object is initiate at the begning of loadMedia methos and contain all neccessery info to load.
    struct LoaderInfo {
        var sessionProvider: SessionProvider
        var entryId: String
        var uiconfId: NSNumber?
        var executor: RequestExecutor
        var apiServerURL: String {
            return self.sessionProvider.serverURL + "/api_v3"
        }
    }
    
    enum OVPMediaProviderError: PKError {
        case invalidParam(paramName: String)
        case invalidKS
        case invalidParams
        case invalidResponse
        case currentlyProcessingOtherRequest
        case serverError(code:String, message:String)
        
        public static let domain = "com.kaltura.playkit.error.OVPMediaProvider"
        
        public static let serverErrorCodeKey = "code"
        public static let serverErrorMessageKey = "message"
        
        public var code: Int {
            switch self {
            case .invalidParam: return 0
            case .invalidKS: return 1
            case .invalidParams: return 2
            case .invalidResponse: return 3
            case .currentlyProcessingOtherRequest: return 4
            case .serverError: return 5
            }
        }
        
        public var errorDescription: String {
            
            switch self {
            case .invalidParam(let param): return "Invalid input param: \(param)"
            case .invalidKS: return "Invalid input ks"
            case .invalidParams: return "Invalid input params"
            case .invalidResponse: return "Response data is empty"
            case .currentlyProcessingOtherRequest: return "Currently Processing Other Request"
            case .serverError(let code, let message): return "Server Error code: \(code), \n message: \(message)"
            }
        }
        
        public var userInfo: [String: Any] {
            switch self {
            case .serverError(let code, let message): return [PhoenixMediaProviderError.serverErrorCodeKey: code,
                                                              PhoenixMediaProviderError.serverErrorMessageKey: message]
            default:
                return [String: Any]()
            }
        }
    }
    
    @objc public var sessionProvider: SessionProvider?
    @objc public var entryId: String?
    @objc public var uiconfId: NSNumber?
    @objc public var referrer: String?
    /// this codec will be filtered out of the sources
    @objc public var codecFilterType: CodecType = .h265
    public var executor: RequestExecutor?
    
    @objc public override init() {}
    
    @objc public init(_ sessionProvider: SessionProvider) {
        self.sessionProvider = sessionProvider
    }
    
    /**
     session provider - which resposible for the ks, prtner id, and base server url
     */
    @discardableResult
    @nonobjc public func set(sessionProvider: SessionProvider?) -> Self {
        self.sessionProvider = sessionProvider
        return self
    }
    
    /**
     entryId - entry which we need to play
     */
    @discardableResult
    @nonobjc public func set(entryId: String?) -> Self {
        self.entryId = entryId
        return self
    }
    
    /**
     uiconfId - UI Configuration id
     */
    @discardableResult
    @nonobjc public func set(uiconfId: NSNumber?) -> Self {
        self.uiconfId = uiconfId
        return self
    }
    
    
    /// set the provider referrer
    ///
    /// - Parameter referrer: the app referrer
    /// - Returns: Self
    @discardableResult
    @nonobjc public func set(referrer: String?) -> Self {
        self.referrer = referrer
        return self
    }
    
    @discardableResult
    @nonobjc public func set(codecFilterType: CodecType) -> Self {
        self.codecFilterType = codecFilterType
        return self
    }
    
    /**
     executor - which resposible for the network, it can be set to
     */
    @discardableResult
    @nonobjc public func set(executor: RequestExecutor?) -> Self {
        self.executor = executor
        return self
    }
    
    @objc public func loadMedia(callback: @escaping (PKMediaEntry?, Error?) -> Void){
        
        // session provider is required in order to have the base url and the partner id
        guard let sessionProvider = self.sessionProvider else {
            PKLog.debug("Proivder must have session info")
            callback(nil, OVPMediaProviderError.invalidParam(paramName: "sessionProvider"))
            return
        }
        
        // entryId is requierd
        guard let entryId = self.entryId else {
            PKLog.debug("Proivder must have entryId")
            callback(nil, OVPMediaProviderError.invalidParam(paramName: "entryId"))
            return
        }
        
        //building the loader info which contain all required fields
        let loaderInfo = LoaderInfo(sessionProvider: sessionProvider, entryId: entryId, uiconfId: self.uiconfId, executor: executor ?? USRExecutor.shared)
        
        self.startLoading(loadInfo: loaderInfo, callback: callback)
    }
    
    func startLoading(loadInfo: LoaderInfo, callback: @escaping (PKMediaEntry?, Error?) -> Void) -> Void {
        
        loadInfo.sessionProvider.loadKS { (resKS, error) in
            
            let mrb = KalturaMultiRequestBuilder(url: loadInfo.apiServerURL)?.setOVPBasicParams()
            var ks: String? = nil
            
            // checking if we got ks from the session, otherwise we should work as anonymous
            if let data = resKS, data.isEmpty == false {
                ks = data
            } else {
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
                PKLog.debug("can't find ks and can't request as anonymous ks (WidgetSession)")
                callback(nil, OVPMediaProviderError.invalidKS)
                return
            }
            
            // Request for Entry data
            let listRequest = OVPBaseEntryService.list(baseURL: loadInfo.apiServerURL,
                                                       ks: token,
                                                       entryID: loadInfo.entryId)
            
            // Request for Entry playback data in order to build sources to play
            let getPlaybackContext =  OVPBaseEntryService.getPlaybackContext(baseURL: loadInfo.apiServerURL,
                                                                             ks: token,
                                                                             entryID: loadInfo.entryId,
                                                                             referrer: self.referrer)
            
            let metadataRequest = OVPBaseEntryService.metadata(baseURL: loadInfo.apiServerURL, ks: token, entryID: loadInfo.entryId)
            
            guard let req1 = listRequest, let req2 = getPlaybackContext, let req3 = metadataRequest else {
                callback(nil, OVPMediaProviderError.invalidParams)
                return
            }
            
            //Building the multi request
            mrb?.add(request: req1)
                .add(request: req2)
                .add(request: req3)
                .set(completion: { (dataResponse: Response) in
                    
                    guard let data = dataResponse.data else {
                        PKLog.debug("didn't get response data")
                        callback(nil, OVPMediaProviderError.invalidResponse)
                        return
                    }
                    
                    let responses: [OVPBaseObject] = OVPMultiResponseParser.parse(data: data)
                    
                    // At leat we need to get response of Entry and Playback, on anonymous we will have additional startWidgetSession call
                    guard responses.count >= 2 else {
                        PKLog.debug("didn't get response for all requests")
                        callback(nil, OVPMediaProviderError.invalidResponse)
                        return
                    }
                    
                    let metaData:OVPBaseObject = responses[responses.count-1]
                    let contextDataResponse: OVPBaseObject = responses[responses.count-2]
                    let mainResponse: OVPBaseObject = responses[responses.count-3]
                    
                    guard let mainResponseData = mainResponse as? OVPList,
                        let entry = mainResponseData.objects?.last as? OVPEntry,
                        let contextData = contextDataResponse as? OVPPlaybackContext,
                        let metadataListObject = metaData as? OVPList,
                        let metadataList = metadataListObject.objects as? [OVPMetadata]
                        else {
                            PKLog.debug("Response is not containing Entry info or playback data")
                            callback(nil, OVPMediaProviderError.invalidResponse)
                            return
                    }
                    
                    // FIXME: remove later when bug on server will be fixed
                    let hevcFlavorAssets = self.createMockHEVCFlavorAssets()
                    let flavorAssetsIds = hevcFlavorAssets.map { $0.id }
                    contextData.flavorAssets.append(contentsOf: hevcFlavorAssets)
                    for i in 0..<contextData.sources.count {
                        contextData.sources[i].flavors?.append(contentsOf: flavorAssetsIds)
                    }
                    
                    if let context = contextDataResponse as? OVPPlaybackContext {
                        if (context.hasBlockAction() != nil) {
                            if let error = context.hasErrorMessage() {
                                callback(nil, OVPMediaProviderError.serverError(code: error.code ?? "", message: error.message ?? ""))
                            } else{
                                callback(nil, OVPMediaProviderError.serverError(code: "Blocked", message: "Blocked"))
                            }
                            return
                        }
                    }
                    
                    // filter sources flavors by codec
                    self.filterFlavors(in: &contextData.sources, using: contextData.flavorAssets, by: self.codecFilterType)
                    
                    var mediaSources: [PKMediaSource] = [PKMediaSource]()
                    contextData.sources.forEach { (source: OVPSource) in
                        //detecting the source type
                        let format = FormatsHelper.getMediaFormat(format: source.format, hasDrm: source.drm != nil)
                        //If source type is not supported source will not be created
                        guard format != .unknown else { return }
                        
                        var ksForURL = resKS
                        
                        // retrieving the ks from the response of StartWidgetSession
                        if responses.count > 2 {
                            if let widgetSession = responses[0] as? OVPStartWidgetSessionResponse {
                                ksForURL = widgetSession.ks
                            }
                        }
                        
                        guard let url = self.playbackURL(loadInfo: loadInfo, source: source, ks: ksForURL) else {
                            PKLog.error("failed to create play url from source, discarding source:\(entry.id),\(source.deliveryProfileId), \(source.format)")
                            return
                        }
                        
                        let drmData = self.buildDRMParams(drm: source.drm)
                        
                        //creating media source with the above data
                        let mediaSource: PKMediaSource = PKMediaSource(id: "\(entry.id)_\(String(source.deliveryProfileId))")
                        mediaSource.drmData = drmData
                        mediaSource.contentUrl = url
                        mediaSource.mediaFormat = format
                        mediaSources.append(mediaSource)
                    }
                    
                    let metaDataItems = self.getMetadata(metadataList: metadataList)
                
                    let mediaEntry: PKMediaEntry = PKMediaEntry(id: entry.id)
                    mediaEntry.duration = entry.duration
                    mediaEntry.sources = mediaSources
                    mediaEntry.metadata = metaDataItems
                    mediaEntry.tags = entry.tags
                    callback(mediaEntry, nil)
                })
            
            if let request = mrb?.build() {
                loadInfo.executor.send(request: request)
            } else {
                callback(nil, OVPMediaProviderError.invalidParams)
            }
        }
    }
    
    private func getMetadata(metadataList: [OVPMetadata]) -> [String: String] {
        var metaDataItems = [String: String]()

        for meta in metadataList {
            do {
                if let metaXML = meta.xml {
                    let xml = try XML.parse(metaXML)
                    if let allNodes = xml["metadata"].all{
                        for element in allNodes {
                            for dataElement in element.childElements {
                                metaDataItems[dataElement.name] = dataElement.text
                            }
                        }
                    }
                }
            } catch {
                PKLog.error("Error occur while trying to parse metadata XML")
            }
        }
        
        return metaDataItems
    }
    
    // Creating the drm data based on scheme
    private func buildDRMParams(drm: [OVPDRM]?) -> [DRMParams]? {
        
        let drmData = drm?.flatMap({ (drm: OVPDRM) -> DRMParams? in
            
            guard let schemeName = drm.scheme  else {
                return nil
            }
            
            let scheme = self.convertScheme(name: schemeName)
            var drmData: DRMParams? = nil
            
            switch scheme {
            case .fairplay :
                guard let certifictae = drm.certificate, let licenseURL = drm.licenseURL else { return nil }
                drmData = FairPlayDRMParams(licenseUri: licenseURL, scheme:scheme, base64EncodedCertificate: certifictae)
            default:
                drmData = DRMParams(licenseUri: drm.licenseURL, scheme: scheme)
                
            }
            
            return drmData
        })
        
        return drmData
    }
    
    // building the url with the SourceBuilder class
    private func playbackURL(loadInfo: LoaderInfo, source: OVPSource, ks: String?) -> URL? {
        
        let formatType = FormatsHelper.getMediaFormat(format: source.format, hasDrm: source.drm != nil)
        var playURL: URL? = nil
        if let flavors =  source.flavors,
            flavors.count > 0 {
            
            let sourceBuilder: SourceBuilder = SourceBuilder()
                .set(baseURL: loadInfo.sessionProvider.serverURL)
                .set(format: source.format)
                .set(entryId: loadInfo.entryId)
                .set(uiconfId: loadInfo.uiconfId?.int64Value)
                .set(flavors: source.flavors)
                .set(partnerId: loadInfo.sessionProvider.partnerId)
                .set(sourceProtocol: source.protocols?.last)
                .set(fileExtension: formatType.fileExtension)
                .set(ks: ks)
            playURL = sourceBuilder.build()
        }
        else {
            playURL = source.url
        }
        
        return playURL
    }
    
    @objc public func cancel(){
        
    }
    
    @objc public func convertScheme(name: String) -> DRMParams.Scheme {
    
        switch (name) {
        case "drm.WIDEVINE_CENC":
            return .widevineCenc;
        case "drm.PLAYREADY_CENC":
            return .playreadyCenc
        case "widevine.WIDEVINE":
            return .widevineClassic
        case "fairplay.FAIRPLAY":
            return .fairplay
        default:
            return .unknown
        }
    }
    
    // FIXME: remove later when server will support
    private func createMockHEVCFlavorAssets() -> [OVPFlavorAsset] {
        var flavorAssets = [OVPFlavorAsset]()
        let flavourParamsIds: [Int] = [
            1801461, 1801471, 1801481, 1801491, 1801501,
            1801511, 1801521, 1801531, 1801541, 1801551
        ]
        let ids: [String] = [
            "1_d7jw3gbk", "1_fduia2v4", "1_o1ig9jsv", "1_o4ie2x2k", "1_w54aa8p6",
            "1_nrb2moco", "1_bosauf1r", "1_443y41aa", "1_kzhtg2pw", "1_kjsn9ymv"
        ]
        let videoCodecId = [
            "hvc1", "hev1", "hev1", "hev1", "hev1",
            "hev1", "hev1", "hev1", "hev1", "hev1"
        ]
        /*let flavourParamsIds: [Int] = [1801461, 1801471, 1801481, 1801491, 1801501]
        let ids: [String] = ["0_,e8rbw59u", "0_uf2z04po", "0_oipic3cp", "0_pyy89j5i", "0_8o51rwag"]
        let videoCodecId = ["hvc1", "hvc1", "hvc1", "hvc1", "hvc1"]*/
        let fileExt = "mp4"
        for i in 0..<ids.count {
            flavorAssets.append(OVPFlavorAsset(id: ids[i], tags: nil, fileExt: fileExt, paramsId: flavourParamsIds[i], videoCodecId: videoCodecId[i]))
        }
        return flavorAssets
    }
    
    private func filterFlavors(in sources: inout [OVPSource], using flavorAssets: [OVPFlavorAsset], by codecFilterType: CodecType) {
        switch codecFilterType {
        case .h264, .h265:
            for (i,source) in sources.enumerated() {
                guard var flavors = source.flavors else { continue }
                for j in (1..<flavors.count).reversed() {
                    guard let flavorAsset = flavorAssets.first(where: { $0.id == flavors[j] }) else { continue }
                    if flavorAsset.codecType != codecFilterType {
                        flavors.remove(at: j)
                    }
                }
                // update the flavors with the new ones
                sources[i].flavors = flavors
            }
        case .unknown: return
        }
    }
}







