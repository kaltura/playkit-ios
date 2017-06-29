// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license,
// unless a different license for a particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import UIKit
import GoogleCast

/**
 
 TVPAPICastBuilder this component will help you to comunicate with Kaltura-custom-receiver.
 
 */
@objc public class BasicCastBuilder: NSObject {
    
    @objc public enum StreamType: Int {
        case live
        case vod
        case unknown
    }
    
    enum BasicBuilderDataError: Error {
        case missingContentId
        case missingWebPlayerURL
        case missingPartnerID
        case missingUIConfId
        case missingStreamType
    }
   
    @objc public var contentId: String!
    @objc public var webPlayerURL: String?
    @objc public var partnerID: String?
    @objc public var uiconfID: String?
    @objc public var adTagURL: String?
    @objc public var metaData: GCKMediaMetadata?
    
    @objc public var streamType = StreamType.unknown {
        didSet {
            switch streamType {
            case .live: self.gckMediaStreamType = .live
            case .vod: self.gckMediaStreamType = .buffered
            case .unknown: self.gckMediaStreamType = .unknown
            }
        }
    }
    private var gckMediaStreamType = GCKMediaStreamType.unknown

    /**
     Set - stream type
     - Parameter contentId: receiver contentId to play ( Entry id, or Asset id )
     */
    @discardableResult
    @nonobjc public func set(streamType: StreamType) -> Self {
        self.streamType = streamType
        return self
    }
    
    /**
     Set - contentId
     - Parameter contentId: receiver contentId to play ( Entry id, or Asset id )
     */
    @discardableResult
    @nonobjc public func set(contentId: String?) -> Self {
        
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
    @nonobjc public func set(adTagURL: String?) -> Self {
        
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
    @nonobjc public func set(webPlayerURL: String?) -> Self {
        
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
    @nonobjc public func set(partnerID: String?) -> Self {
        
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
    @nonobjc public func set(uiconfID: String?) -> Self {
        
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
    @nonobjc public func set(metaData: GCKMediaMetadata?) -> Self{
        
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
        
        guard self.streamType != .unknown else {
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
                                                                 streamType: self.gckMediaStreamType,
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
