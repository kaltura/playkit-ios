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

     var requestId: String { get }
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

   public lazy var requestId: String =  {
        return UUID().uuidString
    }()
    
    public var method: String? = nil
    public var url: URL
    public var jsonBody: JSON? = nil
    public var dataBody: Data? = nil
    public var headers: [String:String]? = nil
    public var timeout: Double = 3
    public var conifiguration: RequestConfiguration? = nil
    public var completion: completionClosures? = nil


    
    public init?(url:String){
        
        if let path = URL(string: url) {
            self.url = path
        }else{
            return nil
        }
        
    }
    
    public func set(url: URL) -> Self{
        self.url = url
        return self
    }
    
    public func set(method: String?) -> Self{
        self.method = method
        return self
    }
    
    public func set(jsonBody:JSON?) -> Self{
        self.jsonBody = jsonBody
        return self
    }
    
    public func set(dataBody: Data?)-> Self{
        self.dataBody = dataBody
        return self
    }
    
    
    public func set(headers: [String: String]?) -> Self{
        self.headers = headers
        return self
    }
    
    public func set(conifiguration:RequestConfiguration?) -> Self{
        self.conifiguration = conifiguration
        return self
    }
    
    public func set(completion:completionClosures?) -> Self{
        self.completion = completion
        return self
    }
    
    
    public func add(headerKey:String, headerValue:String) -> Self {
        
        if (self.headers == nil){
            self.headers = [String:String]()
        }
        
        self.headers![headerKey]  = headerValue
        return self
    }
    
    
    public func setBody(key: String, value:JSON) -> Self {
        
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
