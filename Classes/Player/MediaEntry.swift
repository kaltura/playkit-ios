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
    case vod
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
    
    @objc public enum SourceType: Int {
        case hlsClear
        case hlsFairPlay
        case wvmWideVine
        case mp4Clear
        case unknown
        
        var fileExtension: String {
            get {
                switch self {
                case .hlsClear,
                     .hlsFairPlay:
                    return "m3u8"
                case .wvmWideVine:
                    return "wvm"
                case .mp4Clear:
                    return "mp4"
                case .unknown:
                    return "mp4"
                }
            }
        }
    }
    
    @objc public var id: String
    @objc public var contentUrl: URL?
    @objc public var drmData: [DRMData]?
    @objc public var sourceType: SourceType = .unknown
    @objc public var fileExt: String {
        return contentUrl?.pathExtension ?? ""
    }
    
    private let idKey: String = "id"
    private let contentUrlKey: String = "url"
    private let drmDataKey: String = "drmData"
    private let sourceTypeKey: String = "sourceType"
    
    @objc public convenience init (id: String) {
        self.init(id, contentUrl: nil)
    }
    
    
    @objc public init(_ id: String, contentUrl: URL?, drmData: [DRMData]? = nil, sourceType: SourceType = .unknown) {
        self.id = id
        self.contentUrl = contentUrl
        self.drmData = drmData
        self.sourceType = sourceType
    }
    
    @objc public init(json: Any) {
        
        let sj = getJson(json)
        
        self.id = sj[idKey].string ?? UUID().uuidString
        
        self.contentUrl = sj[contentUrlKey].url
        
        if let drmData = sj[drmDataKey].array {
            self.drmData = drmData.flatMap { DRMData.fromJSON($0) }
        }
        
        if let st = sj[sourceTypeKey].int, let sourceType = SourceType(rawValue: st) {
            self.sourceType = sourceType
        }
        
        super.init()
    }
    
    override public var description: String {
        get {
            return "id : \(self.id), url: \(self.contentUrl)"
        }
    }
}

@objc open class DRMData: NSObject {
    var licenseUri: URL?
    
    init(licenseUri: String?) {
        if let url = licenseUri {
            self.licenseUri = URL(string: url)
        }
    }
    
    @objc public static func fromJSON(_ json: Any) -> DRMData? {
        
        let sj = getJson(json)
        
        guard let licenseUri = sj["licenseUri"].string else { return nil }
        
        if let fpsCertificate = sj["fpsCertificate"].string {
            return FairPlayDRMData(licenseUri: licenseUri, base64EncodedCertificate: fpsCertificate)
        } else {
            return DRMData(licenseUri: licenseUri)
        }
    }
}

public class FairPlayDRMData: DRMData {
    var fpsCertificate: Data?
    
    init(licenseUri: String, base64EncodedCertificate: String) {
        fpsCertificate = Data(base64Encoded: base64EncodedCertificate)
        super.init(licenseUri: licenseUri)
    }
}





