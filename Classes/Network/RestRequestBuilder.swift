//
//  RestRequestBuilder.swift
//  Pods
//
//  Created by Admin on 13/11/2016.
//
//

import UIKit



public protocol RestRequest: Request {
    var baseURL: String { get }
    var service: String? { get }
    var action: String? { get }
}

public class RestRequestBuilder: RequestBuilder, RestRequest{

    public var baseURL: String
    public var service: String?
    public var action: String?
    
    init?(url: String, service: String?, action: String?) {
        
        self.baseURL = url
        
        var path = self.baseURL
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

        guard let url =  URL(string: path)  else {
            return nil
        }
        
        super.init(url: url)
        
        
    }
    
    public func build() -> RestRequest {
        super.build()
        self.add(headerKey: "Content-Type", headerValue: "application/json").add(headerKey: "Accept", headerValue: "application/json")
        self.method = "POST"
        return self
    }
    

}
