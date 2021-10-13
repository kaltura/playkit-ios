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

@objc public enum MediaType: Int, CustomStringConvertible {
    case dvrLive
    case live
    case vod
    case unknown
    
    public var description: String {
        switch self {
        case .dvrLive: return "Live with DVR"
        case .live: return "Live"
        case .vod: return "VOD"
        case .unknown: return "Unknown"
        }
    }
}

fileprivate let idKey = "id"
fileprivate let sourcesKey = "sources"
fileprivate let mediaTypeKey = "mediaType"
fileprivate let durationKey = "duration"
fileprivate let thumbnailUrlKey = "thumbnailUrl"

@objc public class PKMediaEntry: NSObject {
    @objc public var id: String
    @objc public var sources: [PKMediaSource]?
    @objc public var duration: TimeInterval = 0
    @objc public var mediaType: MediaType = .unknown
    @objc public var metadata: [String: String]?
    @objc public var name: String?
    @objc public var externalSubtitles: [PKExternalSubtitle]?
    @objc public var thumbnailUrl: String?
    
    var vrData: VRData?
    public var tags: String? {
        didSet {
            //creating media entry with the above sources
            let vrKey = "360"
            if let mediaTags = self.tags {
                for tag in mediaTags.components(separatedBy: ",") {
                    if tag.trimmingCharacters(in: .whitespaces).equals(vrKey) {
                        self.vrData = VRData()
                        break
                    }
                }
            }
        }
    }
    
    internal init(id: String) {
        self.id = id
        super.init()
    }
    
    @objc public init(_ id: String, sources: [PKMediaSource]?, duration: TimeInterval = 0) {
        self.id = id
        self.sources = sources
        self.duration = duration
        super.init()
    }
    
    @objc public init(json: Any) {
        
        let jsonObject = json as? JSON ?? JSON(json)
        
        self.id = jsonObject[idKey].string ?? ""
        
        self.duration = jsonObject[durationKey].double ?? 0.0
        self.thumbnailUrl = jsonObject[thumbnailUrlKey].string
        
        if let sources = jsonObject[sourcesKey].array {
            self.sources = sources.map { PKMediaSource(json: $0) }
        }
        
        if let mediaTypeStr = jsonObject[mediaTypeKey].string {
            switch mediaTypeStr {
            case "Live":
                self.mediaType = .live
            case "DvrLive":
                self.mediaType = .dvrLive
            case "Vod":
                self.mediaType = .vod
            default:
                break // leave as unknown
            }
        }
        
        super.init()
    }
    
    @objc override public var description: String {
        get {
            return "id : \(self.id)," +
                " sources: \(String(describing: self.sources))," +
                " duration: \(duration)," +
                " mediaType: \(mediaType.description)," +
                " metadata: \(String(describing: metadata))," +
                " name: \(String(describing: name))," +
                " thumbnailUrl: \(String(describing: thumbnailUrl))"
        }
    }
    
    func configureMediaSource(withContentRequestAdapter contentRequestAdapter: PKRequestParamsAdapter) {
        self.sources?.forEach { mediaSource in
            mediaSource.contentRequestAdapter = contentRequestAdapter
        }
    }
}

@objc open class DRMParams: NSObject {
    
    @objc public enum Scheme: Int, CustomStringConvertible {
        case widevineCenc
        case playreadyCenc
        case widevineClassic
        case fairplay
        case unknown
        
        public var description: String {
            switch self {
            case .widevineCenc: return "Widevine Cenc"
            case .playreadyCenc: return "PlayReady Cenc"
            case .widevineClassic: return "Widevine Classic"
            case .fairplay: return "FairPlay"
            case .unknown: return "Unknown"
            }
        }
    }
    
    public var licenseUri: URL?
    public var scheme: Scheme
    public var requestAdapter: PKRequestParamsAdapter?
    
    public init(licenseUri: String?, scheme: Scheme) {
        if let url = licenseUri {
            self.licenseUri = URL(string: url)
        }
        self.scheme = scheme
    }
    
    @objc public static func fromJSON(_ json: Any) -> DRMParams? {
        
        let sj = json as? JSON ?? JSON(json)
        
        guard let licenseUri = sj["licenseUri"].string else { return nil }
        let schemeValue: Int = sj["scheme"].int ?? Scheme.unknown.hashValue
        let scheme: Scheme = Scheme(rawValue: schemeValue) ?? .unknown
        
        if let fpsCertificate = sj["fpsCertificate"].string {
            return FairPlayDRMParams(licenseUri: licenseUri, base64EncodedCertificate: fpsCertificate)
        } else {
            return DRMParams(licenseUri: licenseUri, scheme: scheme)
        }
    }
}

public class FairPlayDRMParams: DRMParams {
    @objc public var fpsCertificate: Data?
    
    internal var licenseProvider: FairPlayLicenseProvider?
    
    @available(*, deprecated, message: "Use init(licenseUri:base64EncodedCertificate:) instead")
    @objc public init(licenseUri: String, scheme: Scheme, base64EncodedCertificate: String) {
        fpsCertificate = Data(base64Encoded: base64EncodedCertificate)
        super.init(licenseUri: licenseUri, scheme: scheme)
    }

    @objc public init(licenseUri: String, base64EncodedCertificate: String) {
        fpsCertificate = Data(base64Encoded: base64EncodedCertificate)
        super.init(licenseUri: licenseUri, scheme: .fairplay)
    }
}

@objc public protocol FairPlayLicenseProvider {
    @objc func getLicense(spc: Data, assetId: String, requestParams: PKRequestParams,
                          callback: @escaping (_ ckc: Data?, _ offlineDuration: TimeInterval, _ error: Error?) -> Void)
}
