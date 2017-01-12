//
//  TVPAPIBuilder.swift
//  Pods
//
//  Created by Rivka Peleg on 20/12/2016.
//
//

import UIKit


/**
 
 TVPAPICastBuilder this component will help you to comunicate with Kaltura-custom-receiver with TVPAPI Server.

 */
public class TVPAPICastBuilder: BasicCastBuilder {
    
    
    enum BasicBuilderDataError: Error {
        case missingInitObject
        case missingFormat
    }

    internal var initObject: [String:Any]!
    internal var format: String!
    internal var isTrailer: Bool!
    
    public override func set(streamType: StreamType?) -> Self{
        super.set(streamType: streamType)
        self.isTrailer = streamType == StreamType.trailer
        
        return self
    }
 
    /**
     Set - initObject
     - Parameter initObject: that the receiver will use to represent the user
     */
    @discardableResult
    public func set(initObject: [String:Any]?) -> Self {
        self.initObject = initObject
        return self
    }
    
    /**
     Set - format
     - Parameter format: the file format that the receiver will play
     */
    @discardableResult
    public func set(format: String?) -> Self {
        self.format = format
        return self
    }
    
    
    /**
     
      In order to comunicate with Kaltura receiver you should have init object and format this will throw exception if the input is not valid
     */
    override func validate() throws {
        
        try super.validate()
        
        guard self.initObject != nil else {
            throw TVPAPICastBuilder.BasicBuilderDataError.missingInitObject
        }
        
        guard self.format != nil else {
            throw TVPAPICastBuilder.BasicBuilderDataError.missingFormat
        }
        
    }
    
    
    /**
        Adding the data relevent for the OTT
     */
    internal override func proxyData() -> [String:Any]? {
        
        let flavorAssets = ["filters":["include":["Format":[self.format!]]]]
        
        JSONSerialization.isValidJSONObject(flavorAssets)
        let baseEntry  = ["vars":["isTrailer":" " + String(self.isTrailer)]]
        var proxyData : [String : Any] = ["flavorassets":flavorAssets,
                                          "baseentry":baseEntry,
                                          "MediaID":self.contentId!,
                                          "iMediaID":self.contentId!]
        
        proxyData["initObj"] = self.initObject!
        return proxyData
    }
}


