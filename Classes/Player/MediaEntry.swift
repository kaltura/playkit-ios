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
    var id: String?
    var sources: [MediaSource]?
    var duration: Int64?
    
    
    
    private let idKey = "id"
    private let sourcesKey = "sources"
    private let durationKey = "duration"
    

    init(json: JSON) {
      
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
    let id: String
    var contentUrl: URL?
    var mimeType: String?
    var drmData: DRMData?
    
    
    
    private let idKey: String = "id"
    private let contentUrlKey: String = "url"
    private let mimeTypeKey: String = "mimeType"
    private let drmDataKey: String = "drmData"
    
    init(id: String) {
        self.id = id
    }
    
    init(json:JSON) {
        self.id = json[idKey].string!
        
        if let pathString = json[contentUrlKey].string {
                self.contentUrl = URL(string: pathString )
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




protocol MediaEntryProviderBuilder {
    func buildProvider() -> MediaEntryProvider?
}


public protocol MediaEntryProvider {
    var mediaEntry: MediaEntry? { get }
    func loadMedia(callback:(_ mediaEntry:MediaEntry)->Void)
}

public class MockMediaEntryProvider : MediaEntryProvider {
    
    public var mediaEntry: MediaEntry?
    private var mediaEntryJson : JSON?
    
    public init(_ mediaEntryJson: JSON?) {
        
        self.mediaEntryJson = mediaEntryJson
    }
    
    public func loadMedia(callback: (MediaEntry) -> Void) {
        
        guard  let json = self.mediaEntryJson else {return}
        let mediaEntry : MediaEntry = MediaEntry(json: json)
        callback(mediaEntry)
    }
}

class MockMediaEntryProviderBuilder: MediaEntryProviderBuilder {
    
    
    public var id : String?
    public var fileURL : URL?
    public var fileContent : Data?
    
    private var objectsByIds : JSON?
    
    typealias BuilderClosure = ( _ mock:MockMediaEntryProviderBuilder) -> ()
    
    init(buildClousure: BuilderClosure) {
        buildClousure(self)
    }
    
    public func buildProvider() -> MediaEntryProvider? {

        guard let id = self.id else {return nil}
        
        if self.fileContent == nil {
            guard let stringPath = self.fileURL?.absoluteString else {return nil}
                self.fileContent = NSData(contentsOfFile: stringPath) as Data?
        }
        
        self.objectsByIds = JSON(data: self.fileContent!)
        guard let objectsJSON = self.objectsByIds else { return nil }
        // 2) get media as json by id:
        let jsonMedia = objectsJSON[id]
        let provider = MockMediaEntryProvider.init(jsonMedia)
        return provider
    }
    
    }




public class TestMediaProvider : NSObject {
    
   override public init() {
        
    }
    
    
    public func test (){
        
        
            MockMediaEntryProviderBuilder { (m:MockMediaEntryProviderBuilder) in
            let bundle = Bundle.main
            let path = bundle.path(forResource: "Entries", ofType: "json")
            guard let filePath = path else {return}
            m.id = "m001"
            m.fileURL = URL(string:path!)
            }.buildProvider()?.loadMedia(callback: { (media:MediaEntry) in
                
                // load the player!
        })
        
       
    }
}



