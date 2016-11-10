//
//  Request.swift
//  Pods
//
//  Created by Admin on 10/11/2016.
//
//

import UIKit

public class Request {
    
    internal var method: String? = nil
    internal var url: URL? = nil
    internal var body: [String:AnyObject]? = nil
    internal var headers: [String:String]? = nil
    internal var timeout: Double = 3
    internal var conifiguration: RequestConfiguration? = nil
    
    
    public init()
    { 
    }
    
    public typealias completionClosures =  (_ response:Response)->Void
    public var completion: completionClosures? = nil
    
    
    public func set(url: URL?) -> Request{
        self.url = url
        return self
    }
    
    public func set(method: String?) -> Request{
        self.method = method
        return self
    }
    
    public func set(body:[String:AnyObject]?) -> Request{
        self.body = body
        return self
    }
    
    public func set(headers: [String: String]?) -> Request{
        self.headers = headers
        return self
    }
    
    public func set(conifiguration:RequestConfiguration?) -> Request{
        self.conifiguration = conifiguration
        return self
    }
    
    public func set(completion:completionClosures?) -> Request{
        self.completion = completion
        return self
    }
    
    
    public func add(headerKey:String, headerValue:String) -> Request {
        
        if (self.headers == nil){
            self.headers = [String:String]()
        }
        
        self.headers![headerKey]  = headerValue
        return self
    }
    
    
    

    
    
}
