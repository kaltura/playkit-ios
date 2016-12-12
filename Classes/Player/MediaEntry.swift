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
    
    public init(json: Any?) {
        let jsonObject = JSON(json)

        if let id = jsonObject[idKey].string {
            self.id = id
        } else {
            self.id = ""
        }
        
        self.duration = jsonObject[durationKey].int64
        var sources : [MediaSource] = [MediaSource]()
        
        if let sourcesKeys = jsonObject[sourcesKey].array {
            for jsonSource in sourcesKeys {
                
                let mediaSource : MediaSource = MediaSource(json: jsonSource)
                sources.append(mediaSource)
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
    var licenseURL: URL?
    
    static func fromJSON(_ json: JSON) -> DRMData? {
        guard let licenseURL = json["licenseUrl"].string else { return nil }
        
        if let fpsCertificate = json["fpsCertificate"].string {
            var fpsData = FairPlayDRMData()
            fpsData.fpsCertificate = Data(base64Encoded: fpsCertificate)
            fpsData.licenseURL = URL(string: licenseURL)
            return fpsData
        } else {
            var drmData = DRMData()
            drmData.licenseURL = URL(string: licenseURL)
            return drmData
        }
    }
}

public class FairPlayDRMData: DRMData {
    var fpsCertificate: Data?
}





