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
        
        
        @discardableResult
        public func set(contentId: String?) -> Self{
            self.contentId = contentId
            return self
        }
        
        @discardableResult
        public func set(adTagURL: String?) -> Self {
            self.adTagURL = adTagURL
            return self
        }
        
        @discardableResult
        public func set(webPlayerURL: String?) -> Self {
            self.webPlayerURL = webPlayerURL
            return self
        }
        
        @discardableResult
        public func set(ks:String?) -> Self {
            self.ks = ks
            return self
            
        }
        
        @discardableResult
        public func set(partnerID: String?) -> Self {
            self.partnerID = partnerID
            return self
        }
        
        @discardableResult
        public func set(uiconfID: String?) -> Self {
            self.uiconfID = uiconfID
            return self
        }
        
        @discardableResult
        public func set(initObject: [String:Any]?) -> Self {
            self.initObject = initObject
            return self
        }
        
        @discardableResult
        public func set(format: String?) -> Self {
            self.format = format
            return self
        }
        
        @discardableResult
        public func set(metaData: GCKMediaMetadata?) -> Self{
            self.metaData = metaData
            return self
        }
        
        
        
        public func build() -> GCKMediaInformation? {
            
            guard let entryId = self.contentId else {
                PKLog.error("entryId must be sent")
                return nil
            }
            
            var embedConfig: [String:Any] = [:]
            embedConfig["lib"] = self.webPlayerURL
            embedConfig["publisherID"] = self.partnerID
            embedConfig["uiconfID"] = self.uiconfID
            embedConfig["entryID"] = entryId
            
            let flashVars = self.flashVars()
            guard JSONSerialization.isValidJSONObject(flashVars) else {
                PKLog.error("flash vars is not valid json")
                return nil
            }
            embedConfig["flashVars"] = flashVars
            let customData: [String:Any] = ["embedConfig":embedConfig]
            let mediaInfo: GCKMediaInformation = GCKMediaInformation(contentID: entryId,
                                                                     streamType: GCKMediaStreamType.unknown,
                                                                     contentType: "",
                                                                     metadata: self.metaData,
                                                                     streamDuration: 0,
                                                                     customData: customData)
            return mediaInfo
        }
        
        
        // MARK - Build flash vars json:
        private func flashVars() -> [String: Any]{
            
            var flashVars = [String:Any]()
            if let proxyData = self.proxyData() {
                PKLog.warning("proxyData is empty")
                flashVars["proxyData"] = proxyData
            }
            
            if let doubleClickPlugin = self.doubleClickPlugin() {
                PKLog.warning("doubleClickPlugin is empty")
                flashVars["doubleClick"] = doubleClickPlugin
            }
            
            return flashVars
        }
        
        private func proxyData() -> [String:Any]? {
            
            guard
                let entryID = self.contentId,
                let format = self.format
                 else {
                return nil
            }
            
            let flavorAssets = ["filters":["include":["Format":[format]]]]
            let baseEntry  = ["vars":["isTrailer":" false"]]
            var proxyData : [String : Any] = ["flavorassets":flavorAssets,
                                              "baseentry":baseEntry,
                                              "MediaID":entryID,
                                              "iMediaID":entryID]
            
            if let ks = self.ks {
              proxyData["ks"] = ks
            }
            
            if let initObject = self.initObject {
              proxyData["initObj"] = initObject
            }
            return proxyData
        }
        
        private func doubleClickPlugin() -> [String:Any]? {
            
            guard let adTagURL = self.adTagURL else {
                return nil
            }
            
            let plugin = ["plugin":"true",
                    "adTagUrl":"\(adTagURL)"]
            return plugin
        }
    }
    
}









