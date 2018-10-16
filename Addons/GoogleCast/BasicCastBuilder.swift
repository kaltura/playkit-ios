// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import UIKit
import GoogleCast

/**
 BasicCastBuilder this component will help you to communicate with Kaltura-custom-receiver.
 */
@objc public class BasicCastBuilder: NSObject {
    
    enum BasicBuilderDataError: Error {
        case missingContentId
        case missingWebPlayerURL
        case missingPartnerID
        case missingUIConfId
        case missingStreamType
        case missingAdTagType
        case missingAdTagURL
    }
    
    @objc public enum StreamType: Int {
        case live
        case vod
        case unknown
    }
    
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
   
    @objc public var contentId: String!
    @objc public var contentType: String = ""
    @objc public var metaData: GCKMediaMetadata?
    @objc public var adBreaks: [GCKAdBreakInfo]?
    @objc public var adBreakClips: [GCKAdBreakClipInfo]?
    @objc public var streamDuration: TimeInterval = 0
    @objc public var mediaTracks: [GCKMediaTrack]?
    @objc public var textTrackStyle: GCKMediaTextTrackStyle?
    
    @objc public var webPlayerURL: String?
    @objc public var partnerID: String?
    @objc public var uiconfID: String?
    @objc public var adTagURL: String?

    // MARK: - Set - Required
    
    /**
     Set - contentId
     - Parameter contentId: Receiver content id to play ( Entry id, or Asset id )
     */
    @discardableResult
    @nonobjc public func set(contentId: String?) -> Self {
        
        guard contentId != nil, contentId?.isEmpty == false else {
                PKLog.warning("Trying to set nil or empty string to content id")
                return self
        }
        
        self.contentId = contentId
        return self
    }
    
    // MARK: - Set - Optional
    
    /**
     Set - streamType
     - Parameter streamType: Receiver stream type to play.
     */
    @discardableResult
    @nonobjc public func set(streamType: StreamType) -> Self {
        
        self.streamType = streamType
        return self
    }
    
    /**
     Set - contentType - Optional
     - Parameter contentType: Receiver content type. The content (MIME) type.
     */
    @discardableResult
    @nonobjc public func set(contentType: String) -> Self {
        
        guard contentType.isEmpty == false else {
                PKLog.warning("Trying to set an empty string to content type")
                return self
        }
        
        self.contentType = contentType
        return self
    }
    
    /**
     Set - metaData - Optional
     - Parameter metaData: Receiver metadata. The media item metadata.
     */
    @discardableResult
    @nonobjc public func set(metaData: GCKMediaMetadata?) -> Self{
        
        guard metaData != nil else {
                PKLog.warning("Trying to set nil to metaData")
                return self
        }
        
        self.metaData = metaData
        return self
    }
    
    /**
     Set - adBreaks - Optional
     - Parameter adBreaks: Receiver ad breaks. The list of ad breaks in this content.
     */
    @discardableResult
    @nonobjc public func set(adBreaks: [GCKAdBreakInfo]?) -> Self {
        
        guard adBreaks != nil else {
            PKLog.verbose("Trying to set nil to adBreaks")
            return self
        }
        
        self.adBreaks = adBreaks
        return self
    }
    
    /**
     Set - adBreakClips - Optional
     - Parameter adBreakClips: Receiver ad break clips. The list of ad break clips in this content.
     */
    @discardableResult
    @nonobjc public func set(adBreakClips: [GCKAdBreakClipInfo]?) -> Self {
        
        guard adBreakClips != nil else {
            PKLog.verbose("Trying to set nil to adBreakClips")
            return self
        }
        
        self.adBreakClips = adBreakClips
        return self
    }
    
    /**
     Set - streamDuration - Optional
     - Parameter streamDuration: Receiver stream duration. The stream duration.
     */
    @discardableResult
    @nonobjc public func set(streamDuration: TimeInterval) -> Self {
        
        self.streamDuration = streamDuration
        return self
    }
    
    /**
     Set - mediaTracks - Optional
     - Parameter mediaTracks: Receiver media tracks. The media tracks.
     */
    @discardableResult
    @nonobjc public func set(mediaTracks: [GCKMediaTrack]?) -> Self {
        
        guard mediaTracks != nil else {
            PKLog.verbose("Trying to set nil to mediaTracks")
            return self
        }
        
        self.mediaTracks = mediaTracks
        return self
    }
    
    /**
     Set - textTrackStyle - Optional
     - Parameter textTrackStyle: Receiver text track style. The text track style.
     */
    @discardableResult
    @nonobjc public func set(textTrackStyle: GCKMediaTextTrackStyle?) -> Self {
        
        guard textTrackStyle != nil else {
            PKLog.verbose("Trying to set nil to textTrackStyle")
            return self
        }
        
        self.textTrackStyle = textTrackStyle
        return self
    }
    
    // MARK: - Set - Kaltura Data
    
    /**
     Set - adTagURL
     - Parameter adTagURL: The advertisments url to play.
     */
    @discardableResult
    @nonobjc public func set(adTagURL: String?) -> Self {
        
        guard adTagURL != nil, adTagURL?.isEmpty == false else {
            PKLog.verbose("Trying to set nil or empty string to adTagURL")
            return self
        }
        
        self.adTagURL = adTagURL
        return self
    }
    
    /**
     Set - webPlayerURL
     - Parameter webPlayerURL: The location of the web player the receiver will use to play content.
     */
    @discardableResult
    @nonobjc public func set(webPlayerURL: String?) -> Self {
        
        guard webPlayerURL != nil, webPlayerURL?.isEmpty == false else {
            PKLog.warning("Trying to set nil or empty string to webPlayerURL")
            return self
        }
        
        self.webPlayerURL = webPlayerURL
        return self
    }
    
    /**
     Set - partnerID
     - Parameter partnerID: The client partner id.
     */
    @discardableResult
    @nonobjc public func set(partnerID: String?) -> Self {
        
        guard partnerID != nil, partnerID?.isEmpty == false else {
            PKLog.warning("Trying to set nil or empty string to partnerID")
            return self
        }
        
        self.partnerID = partnerID
        return self
    }
    
    /**
     Set - uiconfID
     - Parameter uiconfID: The receiver uiconf id that has the configuration for the layout and plugins.
     */
    @discardableResult
    @nonobjc public func set(uiconfID: String?) -> Self {
        
        guard uiconfID != nil, uiconfID?.isEmpty == false else {
            PKLog.warning("Trying to set nil or empty string to uiconfID")
            return self
        }

        self.uiconfID = uiconfID
        return self
    }
    
    // MARK: -
    
    internal func validate() throws {
        
        guard self.contentId != nil else {
            throw BasicCastBuilder.BasicBuilderDataError.missingContentId
        }
    }
    
    /**
     Build GCKMediaInformation a google-cast-sdk object to send through the load google-API 
     */
    @objc public func build() throws -> GCKMediaInformation {
        
        try self.validate()
        let customData = self.customData()
        let mediaInfo: GCKMediaInformation = GCKMediaInformation(contentID: self.contentId,
                                                                 streamType: self.gckMediaStreamType,
                                                                 contentType: self.contentType,
                                                                 metadata: self.metaData,
                                                                 adBreaks: self.adBreaks,
                                                                 adBreakClips: self.adBreakClips,
                                                                 streamDuration: self.streamDuration,
                                                                 mediaTracks: self.mediaTracks,
                                                                 textTrackStyle: self.textTrackStyle,
                                                                 customData: customData)
        
        return mediaInfo
    }
    
    
    // MARK: - Create custom data
    
    
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
