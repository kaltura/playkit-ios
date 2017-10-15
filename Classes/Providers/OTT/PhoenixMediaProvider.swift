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
import SwiftyJSON
import KalturaNetKit


@objc public enum AssetType: Int {
    case media
    case epg
    case unknown
    
    var asString: String {
        switch self {
        case .media: return "media"
        case .epg: return "epg"
        case .unknown: return ""
        }
    }
}


@objc public enum PlaybackContextType: Int {
    
    case trailer
    case catchup
    case startOver
    case playback
    case unknown
    
    var asString: String {
        switch self {
        case .trailer: return "TRAILER"
        case .catchup: return "CATCHUP"
        case .startOver: return "START_OVER"
        case .playback: return "PLAYBACK"
        case .unknown: return ""
        }
    }
}


/************************************************************/
// MARK: - PhoenixMediaProviderError
/************************************************************/

public enum PhoenixMediaProviderError: PKError {

    case invalidInputParam(param: String)
    case unableToParseData(data: Any)
    case noSourcesFound
    case serverError(code:String, message:String)
    /// in case the response data is empty
    case emptyResponse

    public static let domain = "com.kaltura.playkit.error.PhoenixMediaProvider"
    
    public static let serverErrorCodeKey = "code"
    public static let serverErrorMessageKey = "message"

    public var code: Int {
        switch self {
        case .invalidInputParam: return 0
        case .unableToParseData: return 1
        case .noSourcesFound: return 2
        case .serverError: return 3
        case .emptyResponse: return 4
        }
    }

    public var errorDescription: String {

        switch self {
        case .invalidInputParam(let param): return "Invalid input param: \(param)"
        case .unableToParseData(let data): return "Unable to parse object (data: \(String(describing: data)))"
        case .noSourcesFound: return "No source found to play content"
        case .serverError(let code, let message): return "Server Error code: \(code), \n message: \(message)"
        case .emptyResponse: return "Response data is empty"
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

/************************************************************/
// MARK: - PhoenixMediaProvider
/************************************************************/

/* Description
 
    Using Session provider will help you create PKMediaEntry in order to play content with the player
    It's requestig the asset data and creating sources with relevant information for ex' contentURL, licenseURL, fiarPlay certificate and etc'
 
    #Example of code
    ````
    let phoenixMediaProvider = PhoenixMediaProvider()
    .set(type: AssetType.media)
    .set(assetId: asset.assetID)
    .set(fileIds: [file.fileID.stringValue])
    .set(networkProtocol: "https")
    .set(playbackContextType: isTrailer ? PlaybackContextType.trailer : PlaybackContextType.playback)
    .set(sessionProvider: PhoenixSessionManager.shared)

    phoenixMediaProvider.loadMedia(callback: { (media, error) in
    
    if let mediaEntry = media, error == nil {
        self.player?.prepare(MediaConfig.config(mediaEntry: mediaEntry, startTime: params.startOver ? 0 : asset.currentMediaPositionInSeconds))
    }else{
        print("error loading asset: \(error?.localizedDescription)")
        self.delegate?.corePlayer(self, didFailWith:LS("player_error_unable_to_load_entry"))
    }
    ````
})
*/
@objc public class PhoenixMediaProvider: NSObject, MediaEntryProvider {

    @objc public var sessionProvider: SessionProvider?
    @objc public var assetId: String?
    @objc public var type: AssetType = .unknown
    @objc public var formats: [String]?
    @objc public var fileIds: [String]?
    @objc public var playbackContextType: PlaybackContextType = .unknown
    @objc public var networkProtocol: String?
    public weak var responseDelegate: PKMediaEntryProviderResponseDelegate? = nil
    @objc public var referrer: String?
    
    public var executor: RequestExecutor?

    public override init() { }

    /// - Parameter sessionProvider: This provider provider the ks for all wroking request.
    /// If ks is nil, the provider will load the meida with anonymous ks
    /// - Returns: Self ( so you con continue set other parameters after it )
    @discardableResult
    @nonobjc public func set(sessionProvider: SessionProvider?) -> Self {
        self.sessionProvider = sessionProvider
        return self
    }

    /// Required parameter
    ///
    /// - Parameter assetId: asset identifier
    /// - Returns: Self
    @discardableResult
    @nonobjc public func set(assetId: String?) -> Self {
        self.assetId = assetId
        return self
    }

    /// - Parameter type: Asset Object type if it is Media Or EPG
    /// - Returns: Self
    @discardableResult
    @nonobjc public func set(type: AssetType) -> Self {
        self.type = type
        return self
    }

    /// - Parameter playbackContextType: Trailer/Playback/StartOver/Catchup
    /// - Returns: Self
    @discardableResult
    @nonobjc public func set(playbackContextType: PlaybackContextType) -> Self {
        self.playbackContextType = playbackContextType
        return self
    }

    /// - Parameter formats: Asset's requested file formats,
    /// According to this formats array order the sources will be ordered in the mediaEntry
    /// According to this formats sources will be filtered when creating the mediaEntry
    /// - Returns: Self
    @discardableResult
    @nonobjc public func set(formats: [String]?) -> Self {
        self.formats = formats
        return self
    }

    /// - Parameter formats: Asset's requested file ids,
    /// According to this files array order the sources will be ordered in the mediaEntry
    /// According to this ids sources will be filtered when creating the mediaEntry
    /// - Returns: Self
    @discardableResult
    @nonobjc public func set(fileIds: [String]?) -> Self {
        self.fileIds = fileIds
        return self
    }

    /// - Parameter networkProtocol: http/https
    /// - Returns: Self
    @discardableResult
    @nonobjc public func set(networkProtocol: String?) -> Self {
        self.networkProtocol = networkProtocol
        return self
    }

    
    /// - Parameter referrer: the referrer
    /// - Returns: Self
    @discardableResult
    @nonobjc public func set(referrer: String?) -> Self {
        self.referrer = referrer
        return self
    }
    
    /// - Parameter executor: executor which will be used to send request.
    ///    default is USRExecutor
    /// - Returns: Self
    @discardableResult
    @nonobjc public func set(executor: RequestExecutor?) -> Self {
        self.executor = executor
        return self
    }
    
    
    /// - Parameter responseDelegate: responseDelegate which will be used to get the response of the requests are being sent by the mediaProvider
    ///    default is nil
    /// - Returns: Self
    @discardableResult
    @nonobjc public func set(responseDelegate: PKMediaEntryProviderResponseDelegate?) -> Self {
        self.responseDelegate = responseDelegate
        return self
    }

    
    
    

    let defaultProtocol = "https"

    /// This  object is created before loading the media in order to make sure all required attributes are set and we are ready to load
    public struct LoaderInfo {
        var sessionProvider: SessionProvider
        var assetId: String
        var assetType: AssetObjectType
        var formats: [String]?
        var fileIds: [String]?
        var playbackContextType: PlaybackType
        var networkProtocol: String
        var executor: RequestExecutor

    }

    @objc public func loadMedia(callback: @escaping (PKMediaEntry?, Error?) -> Void) {
        guard let sessionProvider = self.sessionProvider else {
            callback(nil, PhoenixMediaProviderError.invalidInputParam(param: "sessionProvider" ).asNSError )
            return
        }
        guard let assetId = self.assetId else {
            callback(nil, PhoenixMediaProviderError.invalidInputParam(param: "assetId" ).asNSError)
            return
        }
        guard self.type != .unknown else {
            callback(nil, PhoenixMediaProviderError.invalidInputParam(param: "type" ).asNSError)
            return
        }
        guard self.playbackContextType != .unknown  else {
            callback(nil, PhoenixMediaProviderError.invalidInputParam(param: "contextType" ).asNSError)
            return
        }

        let pr = self.networkProtocol ?? defaultProtocol
        let executor = self.executor ?? USRExecutor.shared

        let assetType = self.convertAssetTyp(type: self.type)
        let contextPlaybackContextType = self.convertPlaybackContextType(type: self.playbackContextType)
        let loaderParams = LoaderInfo(sessionProvider: sessionProvider, assetId: assetId, assetType: assetType, formats: self.formats, fileIds: self.fileIds, playbackContextType: contextPlaybackContextType, networkProtocol: pr, executor: executor)

        self.startLoad(loaderInfo: loaderParams, callback: callback)
    }

    // This is not implemened yet
    public func cancel() {

    }

    /// This method is creating the request in order to get playback context, when ks id nil we are adding anonymous login request so some times we will have just get context request and some times we will have multi request with getContext request + anonymouse login
    /// - Parameters:
    ///   - ks: ks if exist
    ///   - loaderInfo: info regarding entry to load
    /// - Returns: request builder
    func loaderRequestBuilder(ks: String?, loaderInfo: LoaderInfo) -> KalturaRequestBuilder? {

       let playbackContextOptions = PlaybackContextOptions(playbackContextType: loaderInfo.playbackContextType, protocls: [loaderInfo.networkProtocol], assetFileIds: loaderInfo.fileIds, referrer: self.referrer)

        if let token = ks {

            let playbackContextRequest = OTTAssetService.getPlaybackContext(baseURL:loaderInfo.sessionProvider.serverURL, ks: token, assetId: loaderInfo.assetId, type: loaderInfo.assetType, playbackContextOptions: playbackContextOptions )
            return playbackContextRequest
        } else {

            let anonymouseLoginRequest = OTTUserService.anonymousLogin(baseURL: loaderInfo.sessionProvider.serverURL, partnerId: loaderInfo.sessionProvider.partnerId)
            let ks = "{1:result:ks}"
            let playbackContextRequest = OTTAssetService.getPlaybackContext(baseURL:loaderInfo.sessionProvider.serverURL, ks: ks, assetId: loaderInfo.assetId, type: loaderInfo.assetType, playbackContextOptions: playbackContextOptions )

            guard let req1 = anonymouseLoginRequest, let req2 = playbackContextRequest else {
                return nil
            }

            let multiRquest = KalturaMultiRequestBuilder(url: loaderInfo.sessionProvider.serverURL)?.setOTTBasicParams()
            multiRquest?.add(request: req1).add(request: req2)
            return multiRquest

        }

    }

    /// This method is called after all input is valid and we can start loading media
    ///
    /// - Parameters:
    ///   - loaderInfo: load info
    ///   - callback: completion clousor
    func startLoad(loaderInfo: LoaderInfo, callback: @escaping (PKMediaEntry?, Error?) -> Void) {
        loaderInfo.sessionProvider.loadKS { (ks, error) in

            guard let requestBuilder: KalturaRequestBuilder =  self.loaderRequestBuilder( ks: ks, loaderInfo: loaderInfo) else {
                callback(nil, PhoenixMediaProviderError.invalidInputParam(param:"requests params"))
                return
            }
            
            let isMultiRequest = requestBuilder is KalturaMultiRequestBuilder

            let request = requestBuilder.set(completion: { (response: Response) in

                if let delegate = self.responseDelegate {
                    delegate.providerGotResponse(sender: self, response: response)
                }
                
                if let error = response.error {
                    // if error is of type `PKError` pass it as `NSError` else pass the `Error` object.
                    callback(nil, (error as? PKError)?.asNSError ?? error)
                }
                
                guard let responseData = response.data else {
                    callback(nil, PhoenixMediaProviderError.emptyResponse.asNSError)
                    return
                }
                
                var playbackContext: OTTBaseObject? = nil
                do {
                    if (isMultiRequest) {
                        playbackContext =  try OTTMultiResponseParser.parse(data: responseData).last
                    } else {
                        playbackContext =  try OTTResponseParser.parse(data: responseData)
                    }

                } catch {
                    callback(nil, PhoenixMediaProviderError.unableToParseData(data: responseData).asNSError)
                }

                if let context = playbackContext as? OTTPlaybackContext {
                    let tuple = PhoenixMediaProvider.createMediaEntry(loaderInfo: loaderInfo, context: context)
                    if let error = tuple.1 {
                        callback(nil, error)
                    } else if let media = tuple.0 {
                        if let sources = media.sources, sources.count > 0 {
                            callback(media, nil)
                        } else {
                            callback(nil, PhoenixMediaProviderError.noSourcesFound.asNSError)
                        }
                    }
                } else if let error = playbackContext as? OTTError {
                    callback(nil, PhoenixMediaProviderError.serverError(code: error.code ?? "", message: error.message ?? "").asNSError)
                } else {
                    callback(nil, PhoenixMediaProviderError.unableToParseData(data: responseData).asNSError)
                }
            }).build()

            loaderInfo.executor.send(request: request)
        }
    }

    /// Sorting and filtering source accrding to file formats or file ids
    static func sortedAndFilterSources(by fileIds: [String]?, or fileFormats: [String]?, sources: [OTTPlaybackSource]) -> [OTTPlaybackSource] {

        let orderedSources = sources.filter({ (source: OTTPlaybackSource) -> Bool in
             if let formats = fileFormats {
                return formats.contains(source.type)
             } else if let  fileIds = fileIds {
                return fileIds.contains("\(source.id)")
             } else {
                return true
            }
        })
        .sorted { (source1: OTTPlaybackSource, source2: OTTPlaybackSource) -> Bool in

            if let formats = fileFormats {
                let index1 = formats.index(of: source1.type) ?? 0
                let index2 = formats.index(of: source2.type) ?? 0
                return index1 < index2
            } else if let  fileIds = fileIds {

                let index1 = fileIds.index(of: "\(source1.id)") ?? 0
                let index2 = fileIds.index(of: "\(source2.id)") ?? 0
                return index1 < index2
            } else {
                return false
            }
        }

        return orderedSources
    }

    static public func createMediaEntry(loaderInfo: LoaderInfo, context: OTTPlaybackContext) -> (PKMediaEntry?, NSError?) {

        if context.hasBlockAction() != nil {
            if let error = context.hasErrorMessage() {
                return (nil, PhoenixMediaProviderError.serverError(code: error.code ?? "", message: error.message ?? "").asNSError)
            }
            return (nil, PhoenixMediaProviderError.serverError(code: "Blocked", message: "Blocked").asNSError)
        }
        
        let mediaEntry = PKMediaEntry(id: loaderInfo.assetId)
        let sortedSources = sortedAndFilterSources(by: loaderInfo.fileIds, or: loaderInfo.formats, sources: context.sources)

        var maxDuration: Float = 0.0
        let mediaSources =  sortedSources.flatMap { (source: OTTPlaybackSource) -> PKMediaSource? in

            let format = FormatsHelper.getMediaFormat(format: source.format, hasDrm: source.drm != nil)
            guard  FormatsHelper.supportedFormats.contains(format) else {
                return nil
            }

            var drm: [DRMParams]? = nil
            if let drmData = source.drm, drmData.count > 0 {
                drm = drmData.flatMap({ (drmData: OTTDrmData) -> DRMParams? in

                    let scheme = convertScheme(scheme: drmData.scheme)
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
                guard let mappedDrmData = drm, mappedDrmData.count > 0  else {
                    return nil
                }
            }

            let mediaSource = PKMediaSource(id: "\(source.id)")
            mediaSource.contentUrl = source.url
            mediaSource.mediaFormat = format
            mediaSource.drmData = drm

            maxDuration = max(maxDuration, source.duration)
            return mediaSource

        }

        mediaEntry.sources = mediaSources
        mediaEntry.duration = TimeInterval(maxDuration)

        return (mediaEntry, nil)
    }

    // Mapping between server scheme and local definision of scheme
    static func convertScheme(scheme: String) -> DRMParams.Scheme {
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
                return .unknown
            }
    }
    
    func convertAssetTyp(type: AssetType) -> AssetObjectType {
        
        switch type {
        case .epg:
            return .epg
        case .media:
            return .media
        default:
            return .unknown
        }
    }
    
    func convertPlaybackContextType(type: PlaybackContextType) -> PlaybackType {
        switch type {
        case .catchup:
            return .catchup
        case .playback:
            return .playback
        case .startOver:
            return .startOver
        case .trailer:
            return .trailer
        default:
            return .unknown
        }
    }

}
