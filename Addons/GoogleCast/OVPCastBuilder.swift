//
//  OVPCastBuilder.swift
//  Pods
//
//  Created by Rivka Peleg on 20/12/2016.
//
//

import UIKit



public class OVPCastBuilder: BasicCastBuilder{
    
    internal var ks: String?
    
    @discardableResult
    public func set(ks:String?) -> Self {
        self.ks = ks
        return self
    }
    
    override internal func  proxyData() -> [String:Any]? {
    
        if let ks = self.ks, ks.isEmpty == false {
            
            var proxyData =  [String : Any]()
            proxyData["ks"] = ks
            return proxyData
        }else{
            return nil
        }
    }
    
}

