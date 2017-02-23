//
//  RestRequestBuilder.swift
//  Pods
//
//  Created by Admin on 13/11/2016.
//
//

import UIKit


class KalturaRequestBuilder: RequestBuilder {

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
        
        self.add(headerKey: "Content-Type", headerValue: "application/json").add(headerKey: "Accept", headerValue: "application/json")
        self.set(method: .post)
        
    }
       

}
