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

/**
 
 TVPAPICastBuilder this component will help you to comunicate with Kaltura-custom-receiver with TVPAPI Server.

 */
@objc public class TVPAPICastBuilder: BasicCastBuilder {
    
    enum BasicBuilderDataError: Error {
        case missingInitObject
        case missingFormat
    }

    internal var initObject: [String: Any]!
    internal var format: String!
 
    /**
     Set - initObject
     - Parameter initObject: that the receiver will use to represent the user
     */
    @discardableResult
    @objc public func set(initObject: [String: Any]?) -> Self {
        
        guard initObject != nil
            else {
                PKLog.warning("Trying to set nil to initObject")
                return self
        }
        self.initObject = initObject
        return self
    }
    
    /**
     Set - format
     - Parameter format: the file format that the receiver will play
     */
    @discardableResult
    @objc public func set(format: String?) -> Self {
        
        guard format != nil,
            format?.isEmpty == false
            else {
                PKLog.warning("Trying to set nil or empty string to format")
                return self
        }
        
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
    
    internal override func flashVars() -> [String: Any] {
        
        var flashVars = super.flashVars()
        
        if let proxyData =  self.proxyData() {
            flashVars["proxyData"] = proxyData
        }
        
        return flashVars
    }
    
    /**
        Adding the data relevent for the OTT
     */
    internal func proxyData() -> [String: Any]? {
        
        let flavorAssets = ["filters": ["include": ["Format": [self.format!]]]]
        let config: [String: Any] = ["flavorassets": flavorAssets]
        
        var proxyData = ["MediaID": self.contentId!,
                         "iMediaID": self.contentId!,
                         "mediaType": 0,
                         "withDynamic": false] as [String: Any]
        
        proxyData["config"] = config
        proxyData["initObj"] = self.initObject!
        return proxyData
    }
}


