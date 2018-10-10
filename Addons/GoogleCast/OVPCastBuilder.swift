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
 
 OVPCastBuilder this component will help you to communicate with Kaltura-custom-receiver with OVP-Kaltura Server.
 
 */
@objc public class OVPCastBuilder: BasicCastBuilder{
    
    internal var ks: String?
    
    // MARK: - Set - Kaltura Data
    
    /**
     Set - ks
     The ks which represent the user key, used by the Kaltura Web Player
     */
    @discardableResult
    @objc public func set(ks:String?) -> Self {
        
        guard ks != nil,
            ks?.isEmpty == false
            else {
                PKLog.warning("Trying to set nil or empty string to ks")
                return self
        }
        
        self.ks = ks
        return self
    }
    
    // MARK: -
    
    override func validate() throws {
        
        try super.validate()
        
        guard self.streamType != .unknown else {
            throw BasicCastBuilder.BasicBuilderDataError.missingStreamType
        }
    }
    
    // MARK: - Create custom data
    
    override func embedConfig() -> [String: Any]? {
     
        if var embedConfig = super.embedConfig(), let ks = self.ks , ks.isEmpty == false {
            embedConfig["ks"] = self.ks
            return embedConfig
        }
        
        return super.embedConfig()
    }
    
}

