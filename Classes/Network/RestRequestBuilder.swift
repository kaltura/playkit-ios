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
    var service: String { get }
    var action: String { get }
}

public class RestRequestBuilder: RequestBuilder, RestRequest{

    public var baseURL: String
    public var service: String
    public var action: String
    
    
    init?(baseURL: String, service: String, action: String) {
        
        self.baseURL = baseURL
        self.service = service
        self.action = action
        
        guard let url =  URL(string: baseURL + "/service/" + service + "/action/" + action)  else {
            return nil
        }
        
        super.init(url: url)
        
        self.add(headerKey: "Content-Type", headerValue: "application/json").add(headerKey: "Accept", headerValue: "application/json")
        self.method = "POST"
    }
    
    func build() -> RestRequest {
        return self
    }
}
