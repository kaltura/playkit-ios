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
    
    
    var contentId: String?
    var webPlayerURL: String?
    var partnerID: String?
    var uiconfID: String?
    var adTagURL: String?
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
    
    
    func buildInputData() throws -> BasicBuilderData {
        
        guard let contentId = self.contentId else {
            throw BasicBuilderData.BasicBuilderDataError.missingContentId
        }
        
        guard let webPlayerURL = self.webPlayerURL else {
            throw BasicBuilderData.BasicBuilderDataError.missingwebPlayerURL
        }

        guard let partnerID = self.partnerID else {
            throw BasicBuilderData.BasicBuilderDataError.missingpartnerID
        }

        guard let uiconfID = self.uiconfID else {
            throw BasicBuilderData.BasicBuilderDataError.missingpartnerID
        }
        
        let data = BasicBuilderData(contentId: contentId, webPlayerURL: webPlayerURL, partnerID: partnerID, uiconf: uiconfID)
        return data
    }

    

    public func build() throws -> GCKMediaInformation {
        
        let data = try self.buildInputData()
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
    
    private func customData(data: BasicBuilderData) -> [String:Any]? {
        
        
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
    private func flashVars(data: BasicBuilderData) -> [String: Any]{
        
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
    
    
    private func doubleClickPlugin(data: BasicBuilderData) -> [String:Any]? {
        
        guard let adTagURL = data.adTagURL else {
            return nil
        }
        
        let plugin = ["plugin":"true",
                      "adTagUrl":"\(adTagURL)"]
        return plugin
    }
}






internal class BasicBuilderData {
    
    enum BasicBuilderDataError: Error {
        case missingContentId
        case missingwebPlayerURL
        case missingpartnerID
    }
    
    public var contentId: String
    public var webPlayerURL: String
    public var partnerID: String
    public var uiconfID: String
    public var adTagURL: String?
    public var metaData: GCKMediaMetadata?
    
    public init(contentId: String,
         webPlayerURL: String,
         partnerID: String,
         uiconf:String){
        
        self.contentId = contentId
        self.webPlayerURL = webPlayerURL
        self.partnerID = partnerID
        self.uiconfID = uiconf
    }
    
}


internal class OVPCastBuilderData: BasicBuilderData {
    
    internal var ks: String?
    

    
}


class TVPAPICastBuilderData: BasicBuilderData {
    
    enum BasicBuilderDataError: Error {
        case missingInitObject
        case missingFormat
    }
    
    var initObject: [String:Any]
    var format: String
    
    init(contentId: String,
         webPlayerURL: String,
         partnerID: String,
         initObject: [String:Any],
         format: String,
         uiconf: String) {
        
        self.format = format
        self.initObject = initObject
        super.init(contentId: contentId, webPlayerURL: webPlayerURL, partnerID: partnerID, uiconf: uiconf )
    }
    
}


public class OVPCastBuilder: BasicCastBuilder{
    
    var ks: String?
    
    @discardableResult
    public func set(ks:String?) -> Self {
        self.ks = ks
        return self
    }
    
    override func buildInputData() throws -> BasicBuilderData {
        
        guard let contentId = self.contentId else {
            throw BasicBuilderData.BasicBuilderDataError.missingContentId
        }
        
        guard let webPlayerURL = self.webPlayerURL else {
            throw BasicBuilderData.BasicBuilderDataError.missingwebPlayerURL
        }
        
        guard let partnerID = self.partnerID else {
            throw BasicBuilderData.BasicBuilderDataError.missingpartnerID
        }
        
        guard let uiconfID = self.uiconfID else {
            throw BasicBuilderData.BasicBuilderDataError.missingpartnerID
        }

        
        
        let data = OVPCastBuilderData(contentId: contentId, webPlayerURL: webPlayerURL, partnerID: partnerID,uiconf:uiconfID)
        data.ks = self.ks
        return data
    }
 
    
    override internal func  proxyData(data: BasicBuilderData) -> [String:Any]? {
        guard let OVPData = data as? OVPCastBuilderData else {
            return nil
        }
        
        if let ks = OVPData.ks, ks.isEmpty == false {
            
            var proxyData =  [String : Any]()
            proxyData["ks"] = ks
            return proxyData
        }else{
            return nil
        }
    }
    
}

public class TVPAPICastBuilder: BasicCastBuilder {
    
    

    
    var initObject: [String:Any]?
    var format: String?
    
    
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
    
    
    override func buildInputData() throws -> BasicBuilderData {
        
        guard let contentId = self.contentId else {
            throw BasicBuilderData.BasicBuilderDataError.missingContentId
        }
        
        guard let webPlayerURL = self.webPlayerURL else {
            throw BasicBuilderData.BasicBuilderDataError.missingwebPlayerURL
        }
        
        guard let partnerID = self.partnerID else {
            throw BasicBuilderData.BasicBuilderDataError.missingpartnerID
        }
        
        guard let initObject = self.initObject else {
            throw TVPAPICastBuilderData.BasicBuilderDataError.missingInitObject
        }

        guard let format = self.format else {
            throw TVPAPICastBuilderData.BasicBuilderDataError.missingFormat
        }
        
        guard let uiconf = self.uiconfID else {
            throw TVPAPICastBuilderData.BasicBuilderDataError.missingFormat
        }

        
        return TVPAPICastBuilderData(contentId: contentId, webPlayerURL: webPlayerURL, partnerID: partnerID, initObject: initObject, format: format, uiconf: uiconf)
    }
    
    internal override func proxyData(data: BasicBuilderData) -> [String:Any]? {
        
        guard let TVPAPIData = data as? TVPAPICastBuilderData else {
            return nil
        }

        let flavorAssets = ["filters":["include":["Format":[TVPAPIData.format]]]]
        let baseEntry  = ["vars":["isTrailer":" false"]]
        var proxyData : [String : Any] = ["flavorassets":flavorAssets,
                                          "baseentry":baseEntry,
                                          "MediaID":TVPAPIData.contentId,
                                          "iMediaID":TVPAPIData.contentId]
        
        proxyData["initObj"] = TVPAPIData.initObject
        return proxyData
    }
}




