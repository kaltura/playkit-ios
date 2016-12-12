//
//  MediaEntry.swift
//  PlayKit
//
//  Created by Noam Tamim on 08/10/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

import UIKit
import SwiftyJSON

public class MediaEntry: NSObject {
    internal var id: String
    internal var sources: [MediaSource]?
    internal var duration: Int64?
    
    private let idKey = "id"
    private let sourcesKey = "sources"
    private let durationKey = "duration"
    

    internal init(id: String) {
        self.id = id
        super.init()
    }
    
    public init(dict: [String: Any]) {
        
        self.id = dict[idKey] as? String ?? ""
        
        self.duration = dict[durationKey] as? Int64
        
        var mediaSources = [MediaSource]()
        
        if let sources = dict[sourcesKey] as? [[String: Any]] {
            for source in sources {
                mediaSources.append(MediaSource(dict: source))
            }
        }
        
        self.sources = mediaSources
        
        super.init()
    }
        
    public init(json: Any?) {
        
        let jsonObject = JSON(json)

        if let id = jsonObject[idKey].string {
            self.id = id
        } else {
            self.id = ""
        }
        
        self.duration = jsonObject[durationKey].int64
        var sources = [MediaSource]()
        
        if let sourcesKeys = jsonObject[sourcesKey].array {
            for jsonSource in sourcesKeys {
                sources.append(MediaSource(json: jsonSource))
            }
        }
        
        self.sources = sources
        super.init()
    }
    
    override public var description: String {
        get{
            return "id : \(self.id), sources: \(self.sources)"
        }
    }
}

public class MediaSource: NSObject {
    
    internal var id: String
    internal var contentUrl: URL?
    internal var mimeType: String?
    internal var drmData: DRMData?
    
    private let idKey: String = "id"
    private let contentUrlKey: String = "url"
    private let mimeTypeKey: String = "mimeType"
    private let drmDataKey: String = "drmData"
    
    
    public init (id: String){
        self.id = id
        super.init()
    }
    
    public init(dict: [String:Any]) {
        self.id = dict[idKey] as? String ?? ""
        
        if let contentUrl = dict[contentUrlKey] as? String {
            self.contentUrl = URL(string: contentUrl)
        }
        
        if let mimeType = dict[mimeTypeKey] as? String {
            self.mimeType = mimeType
        }
        
        if let drmData = dict[drmDataKey] as? [String:Any] {
            self.drmData = DRMData.fromDictionary(drmData)
        }
        
        super.init()
    }
    
    public init(json:JSON) {
        self.id = json[idKey].string!
        
        if let pathString = json[contentUrlKey].string {
            self.contentUrl = URL(string: pathString)
        }
        
        if let mimeTypeString = json[mimeTypeKey].string {
            self.mimeType = mimeTypeString
        }
        
        self.drmData = DRMData.fromJSON(json[drmDataKey])

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
    
    
    init(licenseUrl: String) {
        self.licenseUrl = URL(string: licenseUrl)
    }
    
    static func fromDictionary(_ dict: [String:Any]) -> DRMData? {
        
        guard let licenseUrl = dict["licenseUrl"] as? String else { return nil }
        
        if let fpsCertificate = dict["fpsCertificate"] as? String {
            return FairPlayDRMData(licenseUrl: licenseUrl, base64EncodedCertificate: fpsCertificate)
        } else {
            return DRMData(licenseUrl: licenseUrl)
        }

    }
    
    static func fromJSON(_ json: JSON) -> DRMData? {
        guard let licenseUrl = json["licenseUrl"].string else { return nil }
        
        if let fpsCertificate = json["fpsCertificate"].string {
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





