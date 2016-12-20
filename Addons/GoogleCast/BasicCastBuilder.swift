//
//  GoogleCastAddon.swift
//  Pods
//
//  Created by Rivka Peleg on 13/12/2016.
//
//

import UIKit
import GoogleCast


internal class BasicBuilderData {
    
    enum BasicBuilderDataError: Error {
        case missingContentId
        case missingwebPlayerURL
        case missingpartnerID
        case missingUIConfId
    }
    
    internal var contentId: String
    internal var webPlayerURL: String
    internal var partnerID: String
    internal var uiconfID: String
    internal var adTagURL: String?
    internal var metaData: GCKMediaMetadata?
    
    internal init (contentId: String?,
                 webPlayerURL: String?,
                 partnerID: String?,
                 uiconf:String?) throws {
        
        
        guard let ci = contentId else {
            throw BasicBuilderData.BasicBuilderDataError.missingContentId
        }
        
        guard let pURL = webPlayerURL else {
            throw BasicBuilderData.BasicBuilderDataError.missingwebPlayerURL
        }
        
        guard let pi = partnerID else {
            throw BasicBuilderData.BasicBuilderDataError.missingpartnerID
        }
        
        guard let ui = uiconf else {
            throw BasicBuilderData.BasicBuilderDataError.missingUIConfId
        }
        
        
        self.contentId = ci
        self.webPlayerURL = pURL
        self.partnerID = pi
        self.uiconfID = ui
    }
    
}



public class BasicCastBuilder: NSObject {
    
    
    internal var contentId: String?
    internal var webPlayerURL: String?
    internal var partnerID: String?
    internal var uiconfID: String?
    internal var adTagURL: String?
    internal var metaData: GCKMediaMetadata?
    
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
    
    
    internal func validateInput() throws -> BasicBuilderData {
        
        let data = try BasicBuilderData(contentId: self.contentId,
                                    webPlayerURL: self.webPlayerURL,
                                    partnerID: self.partnerID,
                                    uiconf: self.uiconfID)
        return data
    }

    

    public func build() throws -> GCKMediaInformation {
        
        let data = try self.validateInput()
        let customData = self.customData(data: data)
        let mediaInfo: GCKMediaInformation = GCKMediaInformation(contentID:data.contentId,
                                                                 streamType: GCKMediaStreamType.unknown,
                                                                 contentType: "",
                                                                 metadata: self.metaData,
                                                                 streamDuration: 0,
                                                                 customData: customData)
        return mediaInfo
    }
    
    
    
    // MARK - Setup Data
    
    internal func customData(data: BasicBuilderData) -> [String:Any]? {

        var embedConfig: [String:Any] = [:]
        embedConfig["lib"] = data.webPlayerURL
        embedConfig["publisherID"] = data.partnerID
        embedConfig["entryID"] = data.contentId
        embedConfig["uiconfID"] = data.uiconfID
        
        let flashVars = self.flashVars(data: data)
        embedConfig["flashVars"] = flashVars
        let customData: [String:Any] = ["embedConfig":embedConfig]
        return customData
    }
    
    
    // MARK - Build flash vars json:
    internal func flashVars(data: BasicBuilderData) -> [String: Any]{
        
        var flashVars = [String:Any]()
        if let proxyData =  self.proxyData(data: data) {
            PKLog.warning("proxyData is empty")
            flashVars["proxyData"] = proxyData
        }
        
        if let doubleClickPlugin = self.doubleClickPlugin(data: data) {
            PKLog.warning("doubleClickPlugin is empty")
            flashVars["doubleClick"] = doubleClickPlugin
        }
        
        return flashVars
    }
    
    internal func proxyData(data: BasicBuilderData) ->  [String:Any]? {
        // implement in sub classes
        return nil
    }
    
    
    internal func doubleClickPlugin(data: BasicBuilderData) -> [String:Any]? {
        
        guard let adTagURL = data.adTagURL else {
            return nil
        }
        
        let plugin = ["plugin":"true",
                      "adTagUrl":"\(adTagURL)"]
        return plugin
    }
}











