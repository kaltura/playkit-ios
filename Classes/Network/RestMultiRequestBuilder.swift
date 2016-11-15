//
//  RestMultiRequestBuilder.swift
//  Pods
//
//  Created by Admin on 13/11/2016.
//
//

import UIKit
import SwiftyJSON

public class RestMultiRequestBuilder: RestRequestBuilder {

    internal var requests: [RestRequest] = [RestRequest]()
    
    
    
    override init?(url : String, service: String?, action: String?) {
        super.init(url: url, service: "multiRequest", action: nil)
    }

    
    
    convenience public init?(url: URL) {
        self.init(url: url.absoluteString, service: nil, action: nil)
    }
    
    
    
    
    public func add(request:RestRequest) -> RestMultiRequestBuilder {
        
        self.requests.append(request)
        return self
    }
    
    
   override public func build() -> Request {
        
//        self.add(headerKey: "Content-Type", headerValue: "application/json").add(headerKey: "Accept", headerValue: "application/json")
//        self.method = "POST"
        
        if self.jsonBody == nil {
            self.jsonBody = JSON([String:Any]())
        }
        
        var requestCount = 1
        
    for request in self.requests {
        
        if let body = request.jsonBody{
            var singleRequestBody: JSON = body
            singleRequestBody["action"] = JSON(request.action)
            singleRequestBody["service"] =  JSON(request.service)
            self.jsonBody?[String(requestCount)] = singleRequestBody
        }
        requestCount += 1
    }
    
    
    let prefix = "{"
    let suffix = "}"
    var data = prefix.data(using: String.Encoding.utf8)

    for  index in 1..<requestCount {
        do{
            let requestBody = try self.jsonBody?[String(index)].rawData()
            data?.append("\"\(index)\":".data(using: String.Encoding.utf8)!)
            data?.append(requestBody!)
            data?.append(",".data(using: String.Encoding.utf8)!)
        }catch{
            
        }
    }
    
    data?.append(suffix.data(using: String.Encoding.utf8)!)
    self.dataBody = data
    print(String(data: data!, encoding: String.Encoding.utf8))
    return self
    }
}
