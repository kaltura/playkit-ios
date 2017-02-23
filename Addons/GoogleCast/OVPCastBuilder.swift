//
//  OVPCastBuilder.swift
//  Pods
//
//  Created by Rivka Peleg on 20/12/2016.
//
//

import UIKit


/**
 
 TVPAPICastBuilder this component will help you to comunicate with Kaltura-custom-receiver with OVP-Kaltura Server.
 
 */
public class OVPCastBuilder: BasicCastBuilder{
    
    internal var ks: String?
    
    /**
     Set - ks
     The ks which represent the user key, used by the Kaltura Web Player
     */
    @discardableResult
    public func set(ks:String?) -> Self {
        
        guard ks != nil,
            ks?.isEmpty == false
            else {
                PKLog.warning("Trying to set nil or empty string to ks")
                return self
        }
        
        self.ks = ks
        return self
    }
    
  
    override func embedConfig() -> [String: Any]? {
     
        if var embedConfig = super.embedConfig(), let ks = self.ks , ks.isEmpty == false {
            embedConfig["ks"] = self.ks
            return embedConfig
        }
        
        return super.embedConfig()
    }
    
}

