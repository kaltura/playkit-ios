//
//  GoogleCastAddon.swift
//  Pods
//
//  Created by Rivka Peleg on 13/12/2016.
//
//

import UIKit
import GoogleCast


public class BasicCastBuilder: NSObject {
    
    
    enum BasicBuilderDataError: Error {
        case missingContentId
        case missingWebPlayerURL
        case missingPartnerID
        case missingUIConfId
    }
    
    internal var contentId: String!
    internal var webPlayerURL: String!
    internal var partnerID: String!
    internal var uiconfID: String!
    internal var adTagURL: String?
    internal var metaData: GCKMediaMetadata?
    
    
    func validate() throws {
        guard self.contentId != nil else {
            throw BasicCastBuilder.BasicBuilderDataError.missingContentId
        }
        
        guard self.webPlayerURL != nil else {
            throw BasicCastBuilder.BasicBuilderDataError.missingWebPlayerURL
        }
        
        guard self.partnerID != nil else {
            throw BasicCastBuilder.BasicBuilderDataError.missingPartnerID
        }
        
        guard self.uiconfID != nil else {
            throw BasicCastBuilder.BasicBuilderDataError.missingUIConfId
        }

    }
    
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
    public func set(metaData: GCKMediaMetadata?) -> Self{
        self.metaData = metaData
        return self
    }
    
    
    

    

    public func build() throws -> GCKMediaInformation {
        
        let data = try self.validate()
        let customData = self.customData()
        let mediaInfo: GCKMediaInformation = GCKMediaInformation(contentID:self.contentId,
                                                                 streamType: GCKMediaStreamType.unknown,
                                                                 contentType: "",
                                                                 metadata: self.metaData,
                                                                 streamDuration: 0,
                                                                 customData: customData)
        return mediaInfo
    }
    
    
    
    // MARK - Setup Data
    
    internal func customData() -> [String:Any]? {

        var embedConfig: [String:Any] = [:]
        embedConfig["lib"] = self.webPlayerURL
        embedConfig["publisherID"] = self.partnerID
        embedConfig["entryID"] = self.contentId
        embedConfig["uiconfID"] = self.uiconfID
        
        let flashVars = self.flashVars()
        embedConfig["flashVars"] = flashVars
        let customData: [String:Any] = ["embedConfig":embedConfig]
        return customData
    }
    
    
    // MARK - Build flash vars json:
    internal func flashVars() -> [String: Any]{
        
        var flashVars = [String:Any]()
        if let proxyData =  self.proxyData() {
            PKLog.warning("proxyData is empty")
            flashVars["proxyData"] = proxyData
        }
        
        if let doubleClickPlugin = self.doubleClickPlugin() {
            PKLog.warning("doubleClickPlugin is empty")
            flashVars["doubleClick"] = doubleClickPlugin
        }
        
        return flashVars
    }
    
    internal func proxyData() ->  [String:Any]? {
        // implement in sub classes
        return nil
    }
    
    
    internal func doubleClickPlugin() -> [String:Any]? {
        
        guard let adTagURL = self.adTagURL else {
            return nil
        }
        
        let plugin = ["plugin":"true",
                      "adTagUrl":"\(adTagURL)"]
        return plugin
    }
}











