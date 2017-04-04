//
//  OTTEntryProvider.swift
//
//
//  Created by Admin on 13/11/2016.
//
//

import UIKit
import SwiftyJSON
import KalturaNetKit

/************************************************************/
// MARK: - PhoenixMediaProviderError
/************************************************************/
public enum PhoenixMediaProviderError: PKError {

    case invalidInputParam(param: String)
    case unableToParseData(data: Any)
    case noSourcesFound
    case serverError(info:String)

    static let domain = "com.kaltura.playkit.error.PhoenixMediaProvider"

    var code: Int {
        switch self {
        case .invalidInputParam: return 0
        case .unableToParseData: return 1
        case .noSourcesFound: return 2
        case .serverError: return 3
        }
    }

    var errorDescription: String {

        switch self {
        case .invalidInputParam(let param): return "Invalid input param: \(param)"
        case .unableToParseData(let data): return "Unable to parse object"
        case .noSourcesFound: return "No source found to play content"
        case .serverError(let info): return "Server Error: \(info)"
        }
    }

    var userInfo: [String: Any] {
        return [String: Any]()
    }

}

/************************************************************/
// MARK: - PhoenixMediaProvider
/************************************************************/

/* Description
 
    Using Session provider will help you create MediaEntry in order to play content with the player
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

    /// - Parameter executor: executor which will be used to send request.
    ///    default is USRExecutor
    /// - Returns: Self
    @discardableResult
    @nonobjc public func set(executor: RequestExecutor?) -> Self {
        self.executor = executor
        return self
    }

    let defaultProtocol = "https"

    /// This  object is created before loading the media in order to make sure all required attributes are set and we are ready to load
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

        let loaderParams = LoaderInfo(sessionProvider: sessionProvider, assetId: assetId, assetType: self.type, formats: self.formats, fileIds: self.fileIds, playbackContextType: self.playbackContextType, networkProtocol:pr, executor: executor)

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

       let playbackContextOptions = PlaybackContextOptions(playbackContextType: loaderInfo.playbackContextType, protocls: [loaderInfo.networkProtocol], assetFileIds: loaderInfo.fileIds)

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
    func startLoad(loaderInfo: LoaderInfo, callback: @escaping (MediaEntry?, Error?) -> Void) {
        loaderInfo.sessionProvider.loadKS { (ks, error) in

            guard let requestBuilder: KalturaRequestBuilder =  self.loaderRequestBuilder( ks: ks, loaderInfo: loaderInfo) else {
                callback(nil, PhoenixMediaProviderError.invalidInputParam(param:"requests params"))
                return
            }

            let isMultiRequest = requestBuilder is KalturaMultiRequestBuilder

            let request = requestBuilder.set(completion: { (response: Response) in

                var playbackContext: OTTBaseObject? = nil
                do {
                    if (isMultiRequest) {
                        playbackContext =  try OTTMultiResponseParser.parse(data: response.data).last
                    } else {
                        playbackContext =  try OTTResponseParser.parse(data: response.data)
                    }

                } catch {
                    callback(nil, PhoenixMediaProviderError.unableToParseData(data:response.data).asNSError)
                }

                if let context = playbackContext as? OTTPlaybackContext {
                    let media = self.createMediaEntry(loaderInfo: loaderInfo, context: context)
                    if let sources = media.sources, sources.count > 0 {
                       callback(media, nil)
                    } else {
                        callback(nil, PhoenixMediaProviderError.noSourcesFound.asNSError)
                    }
                } else if let error = playbackContext as? OTTError {
                        callback(nil, PhoenixMediaProviderError.serverError(info: error.message ?? "Unknown Error").asNSError)
                } else {
                        callback(nil, PhoenixMediaProviderError.unableToParseData(data: response.data).asNSError)
                }
            }).build()

            loaderInfo.executor.send(request: request)
        }
    }

    /// Sorting and filtering source accrding to file formats or file ids
    func sortedAndFilterSources(by fileIds: [String]?, or fileFormats: [String]?, sources: [OTTPlaybackSource]) -> [OTTPlaybackSource] {

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

    func createMediaEntry(loaderInfo: LoaderInfo, context: OTTPlaybackContext) -> MediaEntry {

        let mediaEntry = MediaEntry(id: loaderInfo.assetId)
        let sortedSources = self.sortedAndFilterSources(by: loaderInfo.fileIds, or: loaderInfo.formats, sources: context.sources)

        var maxDuration: Float = 0.0
        let mediaSources =  sortedSources.flatMap { (source: OTTPlaybackSource) -> MediaSource? in

            let format = FormatsHelper.getMediaFormat(format: source.format, hasDrm: source.drm != nil)
            guard  FormatsHelper.supportedFormats.contains(format) else {
                return nil
            }

            var drm: [DRMParams]? = nil
            if let drmData = source.drm, drmData.count > 0 {
                drm = drmData.flatMap({ (drmData: OTTDrmData) -> DRMParams? in

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
                guard let mappedDrmData = drm, mappedDrmData.count > 0  else {
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

    // Mapping between server scheme and local definision of scheme
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
                return .unknown
            }
    }

}
