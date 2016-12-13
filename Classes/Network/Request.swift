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
    var dataBody: Data? { get }
    var headers: [String:String]? { get }
    var timeout: Double { get }
    var configuration: RequestConfiguration? { get }
    var completion: completionClosures? { get }
}


public struct RequestElement : Request {
    
    public var requestId: String
    public var method: String?
    public var url: URL
    public var dataBody: Data?
    public var headers: [String:String]?
    public var timeout: Double
    public var configuration: RequestConfiguration?
    public var completion: completionClosures?
}


public class RequestBuilder: NSObject {
    
    public lazy var requestId: String =  {
        return UUID().uuidString
    }()
    
    public var method: String? = nil
    public var url: URL
    public var jsonBody: JSON? = nil
    public var headers: [String:String]? = nil
    public var timeout: Double = 3
    public var configuration: RequestConfiguration? = nil
    public var completion: completionClosures? = nil
    
    
    public init?(url:String){
        
        if let path = URL(string: url) {
            self.url = path
        }else{
            return nil
        }
        
    }
    
    @discardableResult
    public func set(url: URL) -> Self{
        self.url = url
        return self
    }
    
    @discardableResult
    public func set(method: String?) -> Self{
        self.method = method
        return self
    }
    
    @discardableResult
    public func set(jsonBody:JSON?) -> Self{
        self.jsonBody = jsonBody
        return self
    }
    
    @discardableResult
    public func set(headers: [String: String]?) -> Self{
        self.headers = headers
        return self
    }
    
    @discardableResult
    public func set(configuration:RequestConfiguration?) -> Self{
        self.configuration = configuration
        return self
    }
    
    @discardableResult
    public func set(completion:completionClosures?) -> Self{
        self.completion = completion
        return self
    }
    
    @discardableResult
    public func add(headerKey:String, headerValue:String) -> Self {
        
        if (self.headers == nil){
            self.headers = [String:String]()
        }
        
        self.headers![headerKey]  = headerValue
        return self
    }
    
    
    @discardableResult
    public func setBody(key: String, value:JSON) -> Self {
        
        if self.jsonBody != nil {
            self.jsonBody![key] = value
        }else{
            self.jsonBody = [key:value]
        }
        return self
    }
    
    public func build() -> Request {
        
        
        var bodyData: Data? = nil
        if let body = self.jsonBody {
            do {
                bodyData = try body.rawData()
            }catch{
                
            }
        }
        return RequestElement(requestId: self.requestId, method:self.method , url: self.url, dataBody: bodyData, headers: self.headers, timeout: self.timeout, configuration: self.configuration, completion: self.completion)
        
        
    }
}







