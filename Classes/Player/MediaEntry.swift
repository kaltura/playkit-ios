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

public enum MediaType {
    case Live
}

public class MediaEntry: NSObject {
    public var id: String
    public var sources: [MediaSource]?
    public var duration: Int64?
    public var mediaType: MediaType?
    
    private let idKey = "id"
    private let sourcesKey = "sources"
    private let mediaTypeKey = "mediaType"
    private let durationKey = "duration"
    

    internal init(id: String) {
        self.id = id
        super.init()
    }
    
    public init(_ id: String, sources: [MediaSource], duration: Int64 = 0) {
        self.id = id
        self.sources = sources
        self.duration = duration
        super.init()
    }
    
    public init(json: Any?) {
        
        let jsonObject = getJson(json)
        
        self.id = jsonObject[idKey].string ?? ""
        
        self.duration = jsonObject[durationKey].int64
        
        if let sources = jsonObject[sourcesKey].array {
            self.sources = sources.map { MediaSource(json: $0) }
        }
        
        if let mediaTypeStr = jsonObject[mediaTypeKey].string {
            if mediaTypeStr == "Live" {
                self.mediaType = MediaType.Live
            }
        }
        
        super.init()
    }
    
    override public var description: String {
        get{
            return "id : \(self.id), sources: \(self.sources)"
        }
    }
}

public class MediaSource: NSObject {
    
    public var id: String
    public var contentUrl: URL?
    public var mimeType: String?
    public var drmData: [DRMData]?
    
    private let idKey: String = "id"
    private let contentUrlKey: String = "url"
    private let mimeTypeKey: String = "mimeType"
    private let drmDataKey: String = "drmData"
    
    
    public convenience init (id: String){
        self.init(id, contentUrl: nil)
    }
    
    public init(_ id: String, contentUrl: URL?, mimeType: String? = nil, drmData: [DRMData]? = nil) {
        self.id = id
        self.contentUrl = contentUrl
        self.mimeType = mimeType
        self.drmData = drmData
    }
    
    public init(json: Any) {
        
        let sj = getJson(json)
        
        self.id = sj[idKey].string ?? UUID().uuidString
        
        self.contentUrl = sj[contentUrlKey].URL
        
        self.mimeType = sj[mimeTypeKey].string
        
        if let drmData = sj[drmDataKey].array {
            self.drmData = drmData.flatMap { DRMData.fromJSON($0) }
        }

        super.init()
    }
    
    override public var description: String {
        get{
            return "id : \(self.id), url: \(self.contentUrl)"
        }
    }
}

open class DRMData: NSObject {
    var licenseUri: URL?
    
    init(licenseUri: String?) {
        if let url = licenseUri {
            self.licenseUri = URL(string: url)
        }
    }
    
    public static func fromJSON(_ json: Any) -> DRMData? {
        
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





