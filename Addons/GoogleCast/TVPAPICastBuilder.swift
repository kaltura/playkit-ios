//
//  TVPAPIBuilder.swift
//  Pods
//
//  Created by Rivka Peleg on 20/12/2016.
//
//

import UIKit

internal class TVPAPICastBuilderData: BasicBuilderData {
    
    enum BasicBuilderDataError: Error {
        case missingInitObject
        case missingFormat
    }
    
    internal var initObject: [String:Any]
    internal var format: String
    
    internal init(contentId: String?,
         webPlayerURL: String?,
         partnerID: String?,
         initObject: [String:Any]?,
         format: String?,
         uiconf: String?) throws {
        
        guard let io = initObject else {
            throw TVPAPICastBuilderData.BasicBuilderDataError.missingInitObject
        }
        
        guard let f = format else {
            throw TVPAPICastBuilderData.BasicBuilderDataError.missingFormat
        }

        
        self.format = f
        self.initObject = io
        try super.init(contentId: contentId, webPlayerURL: webPlayerURL, partnerID: partnerID, uiconf: uiconf )
    }
    
}


public class TVPAPICastBuilder: BasicCastBuilder {
    
    internal var initObject: [String:Any]?
    internal var format: String?
    
    
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
    
    
    internal override func validateInput() throws -> BasicBuilderData {
    
        return try TVPAPICastBuilderData(contentId: self.contentId,
                                     webPlayerURL: self.webPlayerURL,
                                     partnerID: self.partnerID,
                                     initObject: self.initObject,
                                     format: self.format,
                                     uiconf: self.uiconfID)
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


