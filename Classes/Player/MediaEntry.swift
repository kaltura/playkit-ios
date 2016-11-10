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
    internal var id: String?
    internal var sources: [MediaSource]?
    internal var duration: Int64?
    
    private let idKey = "id"
    private let sourcesKey = "sources"
    private let durationKey = "duration"
    

    public init(json: JSON) {
      
        guard let id = json[idKey].string else { return}
        self.id = id
        self.duration = json[durationKey].int64
        var sources : [MediaSource] = [MediaSource]()
        for jsonSource in json[sourcesKey].array! {
            
            let mediaSource : MediaSource = MediaSource(json: jsonSource)
            sources.append(mediaSource)
        }
        
        self.sources = sources
    }
}

public class MediaSource {
    internal var id: String
    internal var contentUrl: URL?
    internal var mimeType: String?
    internal var drmData: DRMData?
    
    
    
    private let idKey: String = "id"
    private let contentUrlKey: String = "url"
    private let mimeTypeKey: String = "mimeType"
    private let drmDataKey: String = "drmData"
    
    
    public init(json:JSON) {
        self.id = json[idKey].string!
        
        if let pathString = json[contentUrlKey].string {
                self.contentUrl = URL(string: pathString)
        }
        
        if let mimeTypeString = json[mimeTypeKey].string {
            self.mimeType = mimeTypeString
        }
    }
}

open class DRMData {
    var licenseURL: URL?
}

public class FairPlayDRMData: DRMData {
    var fpsCertificate: Data?    
}





