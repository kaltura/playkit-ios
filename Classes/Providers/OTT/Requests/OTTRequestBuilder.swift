//
//  RestRequestBuilder.swift
//  Pods
//
//  Created by Admin on 13/11/2016.
//
//

import UIKit


internal class OTTRequestBuilder: RequestBuilder{

    public var service: String?
    public var action: String?

    init?(url: String?, service: String?, action: String?) {
        
        guard let baseURL = url else {
            return nil
        }
        
        var path = baseURL
        if let service = service {
            self.service = service
            let serviceSuffix = "/service/" + service
            path += serviceSuffix
        }
        
        if let action = action {
            self.action = action
            let actionSuffix = "/action/" + action
            path += actionSuffix
        }

        super.init(url: path)
        
    }
    
    
    
    internal func setClientTag() -> Self {
        //self.setBody(key: "clientTag", value: "java:16-09-10")
        self.setBody(key: "clientTag", value: "playkit")
        return self
    }
    
    internal func setApiVersion() -> Self {
        //self.setBody(key: "apiVersion", value: "3.6.1078.11798")
        self.setBody(key: "apiVersion", value: "3.3.0")
        self.setBody(key: "format", value: 1)
        
        return self
    }
    

    

    
    
    public override func build() -> Request {
        super.build()
        
        // OTT:self.add(headerKey: "Content-Type", headerValue: "application/json").add(headerKey: "Accept", headerValue: "application/json")
        
        self.add(headerKey: "Content-Type", headerValue: "application/json").add(headerKey: "Accept", headerValue: "*/*").add(headerKey: "Cache-Control", headerValue: "no-cache")
        self.method = "POST"
        self.setClientTag()
        self.setApiVersion()
        
        return self
    }
    

}
