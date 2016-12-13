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
    
    public var id: String
    public var contentUrl: URL?
    public var mimeType: String?
    public var drmData: DRMData?
    
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
        
        super.init()
    }
    
    override public var description: String {
        get{
            return "id : \(self.id), url: \(self.contentUrl)"
        }
    }
}

open class DRMData: NSObject {
    public var licenseURL: URL?
}

public class FairPlayDRMData: DRMData {
    public var fpsCertificate: Data?    
}





