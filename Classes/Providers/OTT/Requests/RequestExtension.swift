//
//  RequestExtension.swift
//  Pods
//
//  Created by Rivka Peleg on 04/12/2016.
//
//

import UIKit
import SwiftyJSON


extension KalturaRequestBuilder {
    
    internal func setClientTag(clientTag:String) -> Self {
        self.setBody(key: "clientTag", value: JSON(clientTag))
        return self
    }
    
    internal func setApiVersion(apiVersion:String) -> Self {
        self.setBody(key: "apiVersion", value: JSON(apiVersion))
        
        return self
    }
    
    internal func setFormat(format:Int){
        self.setBody(key: "format", value: JSON(format))
    }
    

    internal func setOTTBasicParams() -> Self {
        
        self.setClientTag(clientTag: "java:16-09-10")
        self.setApiVersion(apiVersion: "3.6.1078.11798")
        return self
    }
    
    internal func setOVPBasicParams() -> Void{
        self.setClientTag(clientTag: "playkit")
        self.setApiVersion(apiVersion: "3.3.0")
        self.setFormat(format: 1)

    }
}
