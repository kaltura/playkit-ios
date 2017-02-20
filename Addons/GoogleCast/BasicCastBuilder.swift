//
//  GoogleCastAddon.swift
//  Pods
//
//  Created by Rivka Peleg on 13/12/2016.
//
//

import UIKit
import GoogleCast



/**
 
 TVPAPICastBuilder this component will help you to comunicate with Kaltura-custom-receiver.
 
 */
public class BasicCastBuilder: NSObject {
    
    
    public enum StreamType {
        case live
        case vod
    }
    
    enum BasicBuilderDataError: Error {
        case missingContentId
        case missingWebPlayerURL
        case missingPartnerID
        case missingUIConfId
        case missingStreamType
    }
    
   
    internal var contentId: String!
    internal var webPlayerURL: String?
    internal var partnerID: String!
    internal var uiconfID: String!
    internal var adTagURL: String?
    internal var streamType: GCKMediaStreamType!
    internal var metaData: GCKMediaMetadata?
    

    /**
     Set - stream type
     - Parameter contentId: receiver contentId to play ( Entry id, or Asset id )
     */
    @discardableResult
    public func set(streamType: StreamType?) -> Self{
        
        switch streamType {
        case .live? :
            self.streamType = .live
        default:
            self.streamType = .buffered
            
        }
        return self
    }
    
    /**
     Set - contentId
     - Parameter contentId: receiver contentId to play ( Entry id, or Asset id )
     */
    @discardableResult
    public func set(contentId: String?) -> Self{
        self.contentId = contentId
        return self
    }
    
    /**
     Set - adTagURL
     - Parameter adTagURL: that advertisments url to play
     */
    @discardableResult
    public func set(adTagURL: String?) -> Self {
        self.adTagURL = adTagURL
        return self
    }
    
    /**
     Set - webPlayerURL
     - Parameter webPlayerURL: the location of the web player the receiver will use to play content
     */
    @discardableResult
    public func set(webPlayerURL: String?) -> Self {
        self.webPlayerURL = webPlayerURL
        return self
    }
    
   
    
    /**
     Set - partnerID
     - Parameter partnerID: the client partner id
     */
    @discardableResult
    public func set(partnerID: String?) -> Self {
        self.partnerID = partnerID
        return self
    }
    
    /**
     Set - uiconfID
     - Parameter uiconfID: the receiver uiconf id thet has the configuration for the layout and plugins
     */
    @discardableResult
    public func set(uiconfID: String?) -> Self {
        self.uiconfID = uiconfID
        return self
    }
    
    
    /**
     Set - metaData
     - Parameter metaData: the receiver google meta data
     */
    @discardableResult
    public func set(metaData: GCKMediaMetadata?) -> Self{
        self.metaData = metaData
        return self
    }
    
    
    

    func validate() throws {
        guard self.contentId != nil else {
            throw BasicCastBuilder.BasicBuilderDataError.missingContentId
        }
        
        guard self.partnerID != nil else {
            throw BasicCastBuilder.BasicBuilderDataError.missingPartnerID
        }
        
        guard self.uiconfID != nil else {
            throw BasicCastBuilder.BasicBuilderDataError.missingUIConfId
        }
        
        guard self.streamType != nil else {
            throw BasicCastBuilder.BasicBuilderDataError.missingStreamType
        }
        
    }

    
    /**
     Build GCKMediaInformation a google-cast-sdk object to send through the load google-API 
     */
    public func build() throws -> GCKMediaInformation {
        
        try self.validate()
        let customData = self.customData()
        let mediaInfo: GCKMediaInformation = GCKMediaInformation(contentID:self.contentId,
                                                                 streamType: self.streamType,
                                                                 contentType: "",
                                                                 metadata: self.metaData,
                                                                 streamDuration: 0,
                                                                 customData: customData)
        return mediaInfo
    }
    
    
    
    
    // MARK - Setup custom data
    
    
    /**
     customData - Which used by Kaltura receiver to play the content through the Kaltura Web Player
     */
    internal func customData() -> [String:Any]? {
        
        if let embedConfig = self.embedConfig() {
            let customData: [String:Any] = ["embedConfig":embedConfig]
            return customData
        }
        return nil
    }
    
    
    internal func embedConfig() -> [String:Any]? {
        
        var embedConfig: [String:Any] = [:]
        
        if let lib = self.webPlayerURL {
          embedConfig["lib"] = lib
        }
        
        embedConfig["publisherID"] = self.partnerID
        embedConfig["entryID"] = self.contentId
        embedConfig["uiconfID"] = self.uiconfID
        
        let flashVars = self.flashVars()
        embedConfig["flashVars"] = flashVars
        
        return embedConfig
    }
    

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
        // Can be implemented on sub classes
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











