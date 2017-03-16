//
//  Request.swift
//  Pods
//
//  Created by Admin on 10/11/2016.
//
//

import UIKit
import SwiftyJSON

public typealias completionClosures =  (_ response: Response) -> Void

public enum RequestMethod {
    case get
    case post
    
    /// The `RequestMethod` value, for example for get we need "GET" etc.
    var value: String {
        switch self {
        case .get: return "GET"
        case .post: return "POST"
        }
    }
}

public protocol Request {
    
    var requestId: String { get }
    var method: RequestMethod? { get }
    var url: URL { get }
    var dataBody: Data? { get }
    var headers: [String:String]? { get }
    var timeout: Double { get }
    var configuration: RequestConfiguration? { get }
    var completion: completionClosures? { get }
    var responseSerializer: ResponseSerializer { get }
}

public struct RequestElement: Request {
    
    public var requestId: String
    public var method: RequestMethod?
    public var url: URL
    public var dataBody: Data?
    public var headers: [String:String]?
    public var timeout: Double
    public var configuration: RequestConfiguration?
    public var responseSerializer: ResponseSerializer
    public var completion: completionClosures?
}

@objc public class RequestBuilder: NSObject {
    
    public lazy var requestId: String = {
        return UUID().uuidString
    }()
    
    public var method: RequestMethod? = nil
    public var url: URL
    public var jsonBody: JSON? = nil
    public var headers: [String:String]? = nil
    public var timeout: Double = 3
    public var configuration: RequestConfiguration? = nil
    public var completion: completionClosures? = nil
    public var urlParams: [String: String]? = nil
    public var responseSerializer : ResponseSerializer = JSONSerializer()
    public init?(url: String){
        if let path = URL(string: url) {
            self.url = path
        } else {
            return nil
        }
    }
    
    @discardableResult
    public func set(url: URL) -> Self{
        self.url = url
        return self
    }
    
    @discardableResult
    public func set(method: RequestMethod?) -> Self{
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
    public func set(responseSerializer: ResponseSerializer) -> Self{
        self.responseSerializer = responseSerializer
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
    
    public func setParam(key: String, value:String) -> Self {
        
        if var params = self.urlParams {
            params[key] = value
        }else{
            self.urlParams = [key:value]
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
        
        if let params = self.urlParams, params.count > 0 {
            
            let urlComponents = NSURLComponents()
            urlComponents.host = self.url.host
            urlComponents.scheme = self.url.scheme
            urlComponents.path = self.url.path
            
            var queryItems = [URLQueryItem]()
            for (key, value) in params {
                queryItems.append(URLQueryItem(name: key, value: value))
            }
            
            urlComponents.queryItems = queryItems
            
            if let url = urlComponents.url{
                self.url = url
            }
            
        }
        
        return RequestElement(requestId: self.requestId, method:self.method , url: self.url, dataBody: bodyData, headers: self.headers, timeout: self.timeout, configuration: self.configuration,responseSerializer: self.responseSerializer, completion: self.completion)
    }
}







