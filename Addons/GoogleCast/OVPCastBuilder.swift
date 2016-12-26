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
    
    @discardableResult
    public func set(ks:String?) -> Self {
        self.ks = ks
        return self
    }
    
  
    override func embedConfig() -> [String : Any]? {
     
        if var customData = super.embedConfig(), let ks = self.ks , ks.isEmpty == false {
            customData["ks"] = self.ks
            return customData
        }
        
        return super.embedConfig()
    }
    
}

