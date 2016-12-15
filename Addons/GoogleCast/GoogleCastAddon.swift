//
//  GoogleCastAddon.swift
//  Pods
//
//  Created by Rivka Peleg on 13/12/2016.
//
//

import UIKit
import GoogleCast


public class KPGoogleCastAddon: NSObject {

    public class MediaInfoBuilder: NSObject {
        
        var contentId: String?
        var adTagURL: String?
        var webPlayerURL: String?
        var ks: String?
        var partnerID: String?
        var uiconfID: String?
        var initObject: [String:Any]?
        var format: String?
        var metaData: GCKMediaMetadata?
        
        
        public func set(contentId: String?) -> Self{
            self.contentId = contentId
            return self
        }
        
        public func set(adTagURL: String?) -> Self {
            self.adTagURL = adTagURL
            return self
        }
        
        public func set(webPlayerURL: String?) -> Self {
            self.webPlayerURL = webPlayerURL
            return self
        }
        
        public func set(ks:String?) -> Self {
            self.ks = ks
            return self
            
        }
        
        public func set(partnerID: String?) -> Self {
            self.partnerID = partnerID
            return self
        }
        
        public func set(uiconfID: String?) -> Self {
            self.uiconfID = uiconfID
            return self
        }
        
        public func set(initObject: [String:Any]?) -> Self {
            self.initObject = initObject
            return self
        }
        
        public func set(format: String?) -> Self {
            self.format = format
            return self
        }
        
        public func set(metaData: GCKMediaMetadata?) -> Self{
            self.metaData = metaData
            return self
        }
        
        func flashVars() -> [String: Any]{
            let proxyData = self.proxyData()
            let doubleClickPlugin = self.doubleClickPlugin()
            var flashVars: [String:Any] = ["proxyData":proxyData,
                                           "doubleClick":doubleClickPlugin]
            return flashVars
        }
        
        func proxyData() -> [String:Any] {
            let entryId = self.contentId
            let flavorAssets = ["filters":["include":["Format":[self.format]]]]
            let baseEntry  = ["vars":["isTrailer":" false"]]
            let proxyData : [String : Any] = ["flavorassets":flavorAssets,
                                              "baseentry":baseEntry,
                                              "ks":self.ks,
                                              "MediaID":entryId,
                                              "iMediaID":entryId,
                                              "initObj":self.initObject]
            return proxyData
        }
        
        func doubleClickPlugin() -> [String:Any] {
            
            let adTagURL = self.adTagURL
            let plugin = ["plugin":"true",
                    "adTagUrl":adTagURL]
            return plugin
        }

        
        
        public func build() -> GCKMediaInformation? {
            
            guard let entryId = self.contentId else {
                return nil
            }
            
            var embedConfig: [String:Any] = [:]
            embedConfig["lib"] = self.webPlayerURL
            embedConfig["publisherID"] = self.partnerID
            embedConfig["uiconfID"] = self.uiconfID
            embedConfig["entryID"] = entryId
            let customData: [String:Any] = ["embedConfig":embedConfig]
            let mediaInfo: GCKMediaInformation = GCKMediaInformation(contentID: entryId,
                                                                     streamType: GCKMediaStreamType.unknown,
                                                                     contentType: "",
                                                                     metadata: self.metaData,
                                                                     streamDuration: 0,
                                                                     customData: customData)
            return mediaInfo
        }
    }
    
}









