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

public class MediaEntry: NSObject {
    public var id: String
    public var sources: [MediaSource]?
    public var duration: Int64?
    
    private let idKey = "id"
    private let sourcesKey = "sources"
    private let durationKey = "duration"
    

    internal init(id: String) {
        self.id = id
        super.init()
    }
    
    public init(json: Any?) {
        
        let jsonObject = getJson(json)
        
        self.id = jsonObject[idKey].string ?? ""
        
        self.duration = jsonObject[durationKey].int64
        
        if let sources = jsonObject[sourcesKey].array {
            self.sources = sources.map { MediaSource(json: $0) }
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
    
    
    public init (id: String){
        self.id = id
        super.init()
    }
    
    public init(json: Any) {
        
        let jsonObj = getJson(json)
        
        self.id = jsonObj[idKey].string ?? UUID().uuidString
        
        self.contentUrl = jsonObj[contentUrlKey].URL
        
        self.mimeType = jsonObj[mimeTypeKey].string
        
        if let drmData = jsonObj[drmDataKey].array {
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
    var licenseUrl: URL?
    
    init(licenseUrl: String?) {
        if let url = licenseUrl {
            self.licenseUrl = URL(string: url)
        }
    }
    
    static func fromJSON(_ json: Any) -> DRMData? {
        
        let jsonObj = getJson(json)
        
        guard let licenseUrl = jsonObj["licenseUrl"].string else { return nil }
        
        if let fpsCertificate = jsonObj["fpsCertificate"].string {
            return FairPlayDRMData(licenseUrl: licenseUrl, base64EncodedCertificate: fpsCertificate)
        } else {
            return DRMData(licenseUrl: licenseUrl)
        }
    }
}

public class FairPlayDRMData: DRMData {
    var fpsCertificate: Data?
    
    init(licenseUrl: String, base64EncodedCertificate: String) {
        fpsCertificate = Data(base64Encoded: base64EncodedCertificate)
        super.init(licenseUrl: licenseUrl)
    }
}





