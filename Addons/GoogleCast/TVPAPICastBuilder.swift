//
//  TVPAPIBuilder.swift
//  Pods
//
//  Created by Rivka Peleg on 20/12/2016.
//
//

import UIKit



public class TVPAPICastBuilder: BasicCastBuilder {
    
    
    enum BasicBuilderDataError: Error {
        case missingInitObject
        case missingFormat
    }

    internal var initObject: [String:Any]!
    internal var format: String!
    
    
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
    
    
    
    override func validate() throws {
        
        guard self.initObject != nil else {
            throw TVPAPICastBuilder.BasicBuilderDataError.missingInitObject
        }
        
        guard self.format != nil else {
            throw TVPAPICastBuilder.BasicBuilderDataError.missingFormat
        }
        
    }
    
    
    internal override func proxyData() -> [String:Any]? {
        

        let flavorAssets = ["filters":["include":["Format":[self.format!]]]]
        
        JSONSerialization.isValidJSONObject(flavorAssets)
        let baseEntry  = ["vars":["isTrailer":" false"]]
        var proxyData : [String : Any] = ["flavorassets":flavorAssets,
                                          "baseentry":baseEntry,
                                          "MediaID":self.contentId!,
                                          "iMediaID":self.contentId!]
        
        proxyData["initObj"] = self.initObject!
        return proxyData
    }
}


