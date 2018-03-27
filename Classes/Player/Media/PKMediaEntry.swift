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

@objc public enum MediaType: Int {
    case live
    case vod
    case unknown
}

@objc public class PKMediaEntry: NSObject {
    @objc public var id: String
    @objc public var sources: [PKMediaSource]?
    @objc public var duration: TimeInterval = 0
    @objc public var mediaType: MediaType = .unknown
    @objc public var metadata: [String: String]?
   
    var vrData: VRData?
    var tags: String? {
        didSet {
            //creating media entry with the above sources
            let vrKey = "360"
            if let mediaTags = self.tags, mediaTags.contains(vrKey) {
                self.vrData = VRData()
            }
        }
    }
    
    private let idKey = "id"
    private let sourcesKey = "sources"
    private let mediaTypeKey = "mediaType"
    private let durationKey = "duration"
    
    internal init(id: String) {
        self.id = id
        super.init()
    }
    
    @objc public init(_ id: String, sources: [PKMediaSource], duration: TimeInterval = 0) {
        self.id = id
        self.sources = sources
        self.duration = duration
        super.init()
    }
    
    @objc public init(json: Any) {
        
        let jsonObject = json as? JSON ?? JSON(json)
        
        self.id = jsonObject[idKey].string ?? ""
        
        self.duration = jsonObject[durationKey].double ?? 0.0
        
        if let sources = jsonObject[sourcesKey].array {
            self.sources = sources.map { PKMediaSource(json: $0) }
        }
        
        if let mediaTypeStr = jsonObject[mediaTypeKey].string {
            if mediaTypeStr == "Live" {
                self.mediaType = MediaType.live
            }
        }
        
        super.init()
    }
    
    @objc override public var description: String {
        get {
            return "id : \(self.id), sources: \(String(describing: self.sources))"
        }
    }
    
    func configureMediaSource(withContentRequestAdapter contentRequestAdapter: PKRequestParamsAdapter) {
        self.sources?.forEach { mediaSource in
            mediaSource.contentRequestAdapter = contentRequestAdapter
        }
    }
}

@objc open class DRMParams: NSObject {
    
    @objc public enum Scheme: Int {
        case widevineCenc
        case playreadyCenc
        case widevineClassic
        case fairplay
        case unknown
    }
    
    var licenseUri: URL?
    var scheme: Scheme
    var requestAdapter: PKRequestParamsAdapter?
    
    init(licenseUri: String?, scheme: Scheme) {
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
            return FairPlayDRMParams(licenseUri: licenseUri, scheme: .fairplay, base64EncodedCertificate: fpsCertificate)
        } else {
            return DRMParams(licenseUri: licenseUri, scheme: scheme)
        }
    }
}

public class FairPlayDRMParams: DRMParams {
    @objc var fpsCertificate: Data?
    
    @objc init(licenseUri: String, scheme: Scheme, base64EncodedCertificate: String) {
        fpsCertificate = Data(base64Encoded: base64EncodedCertificate)
        super.init(licenseUri: licenseUri, scheme: scheme)
    }
}
