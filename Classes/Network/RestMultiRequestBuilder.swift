//
//  RestMultiRequestBuilder.swift
//  Pods
//
//  Created by Admin on 13/11/2016.
//
//

import UIKit
import SwiftyJSON

class RestMultiRequestBuilder: RequestBuilder {

    internal var requests: [RestRequest] = [RestRequest]()
    
    override init?(url: URL) {
        guard let multiRequestUrl = URL(string:url.absoluteString + "/multiRequest" ) else{
            return nil
        }
        super.init(url: multiRequestUrl)
    }
    
    
    func add(request:RestRequest) -> RestMultiRequestBuilder {
        
        self.requests.append(request)
        return self
    }
    
    
    override func build() -> Request {
        
        var body = JSON([String:Any]())
        var requestCount = 1
        
        for request in self.requests {
            
            var singleRequestBody = JSON(request.body)
            singleRequestBody["action"] = JSON(request.action)
            singleRequestBody["service"] =  JSON(request.service)
            body[requestCount] = singleRequestBody
            requestCount += 1
        }
        
        self.body = body
        return self
    }
}
