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
@objc public class BasicCastBuilder: NSObject {
    @objc public enum StreamType: Int {
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
    internal var partnerID: String?
    internal var uiconfID: String?
    internal var adTagURL: String?
    internal var streamType: GCKMediaStreamType!
    internal var metaData: GCKMediaMetadata?
    

    /**
     Set - stream type
     - Parameter contentId: receiver contentId to play ( Entry id, or Asset id )
     */
    @discardableResult
    @objc public func set(streamType: StreamType) -> Self{
        
        switch streamType {
        case .live :
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
    @objc public func set(contentId: String?) -> Self{
        
        guard contentId != nil,
            contentId?.isEmpty == false
            else {
                PKLog.warning("Trying to set nil or empty string to content id")
                return self
        }
        
        self.contentId = contentId
        return self
    }
    
    /**
     Set - adTagURL
     - Parameter adTagURL: that advertisments url to play
     */
    @discardableResult
    @objc public func set(adTagURL: String?) -> Self {
        
        guard adTagURL != nil,
            adTagURL?.isEmpty == false
            else {
                PKLog.warning("Trying to set nil or empty string to adTagURL")
                return self
        }
        
        self.adTagURL = adTagURL
        return self
    }
    
    /**
     Set - webPlayerURL
     - Parameter webPlayerURL: the location of the web player the receiver will use to play content
     */
    @discardableResult
    @objc public func set(webPlayerURL: String?) -> Self {
        
        guard webPlayerURL != nil,
            webPlayerURL?.isEmpty == false
            else {
                PKLog.warning("Trying to set nil or empty string to webPlayerURL")
                return self
        }
        
        self.webPlayerURL = webPlayerURL
        return self
    }
    
   
    
    /**
     Set - partnerID
     - Parameter partnerID: the client partner id
     */
    @discardableResult
    @objc public func set(partnerID: String?) -> Self {
        
        guard partnerID != nil,
            partnerID?.isEmpty == false
            else {
                PKLog.warning("Trying to set nil or empty string to partnerID")
                return self
        }
        
        self.partnerID = partnerID
        return self
    }
    
    /**
     Set - uiconfID
     - Parameter uiconfID: the receiver uiconf id thet has the configuration for the layout and plugins
     */
    @discardableResult
    @objc public func set(uiconfID: String?) -> Self {
        
        guard uiconfID != nil,
            uiconfID?.isEmpty == false
            else {
                PKLog.warning("Trying to set nil or empty string to uiconfID")
                return self
        }

        self.uiconfID = uiconfID
        return self
    }
    
    
    /**
     Set - metaData
     - Parameter metaData: the receiver google meta data
     */
    @discardableResult
    @objc public func set(metaData: GCKMediaMetadata?) -> Self{
        
        guard metaData != nil
            else {
                PKLog.warning("Trying to set nil to metaData")
                return self
        }
        
        self.metaData = metaData
        return self
    }
    
    
    func validate() throws {
        guard self.contentId != nil else {
            throw BasicCastBuilder.BasicBuilderDataError.missingContentId
        }
        
        guard self.streamType != nil else {
            throw BasicCastBuilder.BasicBuilderDataError.missingStreamType
        }
        
        
    }

    
    /**
     Build GCKMediaInformation a google-cast-sdk object to send through the load google-API 
     */
    @objc public func build() throws -> GCKMediaInformation {
        
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
        
        embedConfig["entryID"] = self.contentId
        
        if let lib = self.webPlayerURL {
          embedConfig["lib"] = lib
        }
        
        if let publisherID = self.partnerID {
           embedConfig["publisherID"] = publisherID
        }
        
        if let confID = self.uiconfID{
           embedConfig["uiconfID"] = confID
        }
        
        let flashVars = self.flashVars()
        embedConfig["flashVars"] = flashVars
        
        return embedConfig
    }
    

    internal func flashVars() -> [String: Any]{
        
        var flashVars = [String:Any]()
        
        if let doubleClickPlugin = self.doubleClickPlugin() {
            flashVars["doubleClick"] = doubleClickPlugin
        }        
        return flashVars
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
