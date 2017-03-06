//
//  MediaEntry.swift
//  PlayKit
//
//  Created by Noam Tamim on 08/10/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

import UIKit
import SwiftyJSON

func getJson(_ json: Any) -> JSON {
    return json as? JSON ?? JSON(json)
}

@objc public enum MediaType: Int {
    case live
    case unknown
}

@objc public class MediaEntry: NSObject {
    @objc public var id: String
    @objc public var sources: [MediaSource]?
    @objc public var duration: TimeInterval = 0
    @objc public var mediaType: MediaType = .unknown
    @objc public var metadata:[String:String]?
    
    private let idKey = "id"
    private let sourcesKey = "sources"
    private let mediaTypeKey = "mediaType"
    private let durationKey = "duration"
    
    internal init(id: String) {
        self.id = id
        super.init()
    }
    
    public init(_ id: String, sources: [MediaSource], duration: TimeInterval = 0) {
        self.id = id
        self.sources = sources
        self.duration = duration
        super.init()
    }
    
    public init(json: Any?) {
        
        let jsonObject = getJson(json)
        
        self.id = jsonObject[idKey].string ?? ""
        
        self.duration = jsonObject[durationKey].double ?? 0.0
        
        if let sources = jsonObject[sourcesKey].array {
            self.sources = sources.map { MediaSource(json: $0) }
        }
        
        if let mediaTypeStr = jsonObject[mediaTypeKey].string {
            if mediaTypeStr == "Live" {
                self.mediaType = MediaType.live
            }
        }
        
        super.init()
    }
    
    override public var description: String {
        get {
            return "id : \(self.id), sources: \(self.sources)"
        }
    }
}

@objc public class MediaSource: NSObject {
    
    @objc public enum MediaFormat: Int {
        case dash
        case hls
        case wvm
        case mp4
        case mp3
        case none
        
        
        var fileExtension: String {
            get {
                switch self {
                case .dash:
                    return "mpd"
                case .hls:
                    return "m3u8"
                case .wvm:
                    return "wvm"
                case .mp4:
                    return "mp4"
                case .mp3:
                    return "mp3"
                case .none:
                    return ""
                }
            }
        }
        
    }
    
    @objc public var id: String
    @objc public var contentUrl: URL?
    @objc public var mimeType: String?
    @objc public var drmData: [DRMParams]?
    @objc public var mediaFormat: MediaFormat = .none
    @objc public var fileExt: String {
        return contentUrl?.pathExtension ?? ""
    }
    
    private let idKey: String = "id"
    private let contentUrlKey: String = "url"
    private let mimeTypeKey: String = "mimeType"
    private let drmDataKey: String = "drmData"
    private let formatTypeKey: String = "sourceType"
    
    @objc public convenience init (id: String) {
        self.init(id, contentUrl: nil)
    }
    
    @objc public init(_ id: String, contentUrl: URL?, mimeType: String? = nil, drmData: [DRMParams]? = nil, mediaFormat: MediaFormat = .none) {
        self.id = id
        self.contentUrl = contentUrl
        self.mimeType = mimeType
        self.drmData = drmData
        self.mediaFormat = mediaFormat
    }
    
    @objc public init(json: Any) {
        
        let sj = getJson(json)
        
        self.id = sj[idKey].string ?? UUID().uuidString
        
        self.contentUrl = sj[contentUrlKey].url
        
        self.mimeType = sj[mimeTypeKey].string
        
        if let drmData = sj[drmDataKey].array {
            self.drmData = drmData.flatMap { DRMParams.fromJSON($0) }
        }
        
        if let st = sj[formatTypeKey].int, let mediaFormat = MediaFormat(rawValue: st) {
            self.mediaFormat = mediaFormat
        }
        
        super.init()
    }
    
    override public var description: String {
        get {
            return "id : \(self.id), url: \(self.contentUrl)"
        }
    }
}

@objc open class DRMParams: NSObject {
    var licenseUri: URL?
    
    init(licenseUri: String?) {
        if let url = licenseUri {
            self.licenseUri = URL(string: url)
        }
    }
    
    @objc public static func fromJSON(_ json: Any) -> DRMParams? {
        
        let sj = getJson(json)
        
        guard let licenseUri = sj["licenseUri"].string else { return nil }
        
        if let fpsCertificate = sj["fpsCertificate"].string {
            return FairPlayDRMParams(licenseUri: licenseUri, base64EncodedCertificate: fpsCertificate)
        } else {
            return DRMParams(licenseUri: licenseUri)
        }
    }
}

public class FairPlayDRMParams: DRMParams {
    var fpsCertificate: Data?
    
    init(licenseUri: String, base64EncodedCertificate: String) {
        fpsCertificate = Data(base64Encoded: base64EncodedCertificate)
        super.init(licenseUri: licenseUri)
    }
}





