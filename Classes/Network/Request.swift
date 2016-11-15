//
//  Request.swift
//  Pods
//
//  Created by Admin on 10/11/2016.
//
//

import UIKit
import SwiftyJSON

public typealias completionClosures =  (_ response:Response)->Void

public protocol Request {

     var method: String? { get }
     var url: URL { get }
     var jsonBody: JSON? { get }
     var dataBody: Data? { get }
     var headers: [String:String]? { get }
     var timeout: Double { get }
     var conifiguration: RequestConfiguration? { get }
     var completion: completionClosures? { get }
}

public class RequestBuilder : Request {
    


    public var method: String? = nil
    public var url: URL
    public var jsonBody: JSON? = nil
    public var dataBody: Data? = nil
    public var headers: [String:String]? = nil
    public var timeout: Double = 3
    public var conifiguration: RequestConfiguration? = nil
    public var completion: completionClosures? = nil


    
    public init?(url:URL){
        self.url = url
    }
    
    public func set(url: URL) -> RequestBuilder{
        self.url = url
        return self
    }
    
    public func set(method: String?) -> RequestBuilder{
        self.method = method
        return self
    }
    
    public func set(jsonBody:JSON?) -> RequestBuilder{
        self.jsonBody = jsonBody
        return self
    }
    
    public func set(dataBody: Data?)-> RequestBuilder{
        self.dataBody = dataBody
        return self
    }
    
    
    public func set(headers: [String: String]?) -> RequestBuilder{
        self.headers = headers
        return self
    }
    
    public func set(conifiguration:RequestConfiguration?) -> RequestBuilder{
        self.conifiguration = conifiguration
        return self
    }
    
    public func set(completion:completionClosures?) -> RequestBuilder{
        self.completion = completion
        return self
    }
    
    
    public func add(headerKey:String, headerValue:String) -> RequestBuilder {
        
        if (self.headers == nil){
            self.headers = [String:String]()
        }
        
        self.headers![headerKey]  = headerValue
        return self
    }
    
    
    public func setBody(key: String, value:JSON) -> RequestBuilder {
        
        if var body = self.jsonBody {
            self.jsonBody![key] = value
        }else{
            self.jsonBody = [key:value]
        }
        return self
    }
    
    public func build() -> Request {
        return self
    }
    
    
    

    
    
}
