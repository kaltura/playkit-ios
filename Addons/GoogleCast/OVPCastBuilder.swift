//
//  OVPCastBuilder.swift
//  Pods
//
//  Created by Rivka Peleg on 20/12/2016.
//
//

import UIKit

internal class OVPCastBuilderData: BasicBuilderData {
    
    internal var ks: String?
}


public class OVPCastBuilder: BasicCastBuilder{
    
    internal var ks: String?
    
    @discardableResult
    public func set(ks:String?) -> Self {
        self.ks = ks
        return self
    }
    
    override internal func validateInput() throws -> BasicBuilderData {
        
        let data = try OVPCastBuilderData(contentId: self.contentId, webPlayerURL: self.webPlayerURL, partnerID: self.partnerID,uiconf:self.uiconfID)
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

