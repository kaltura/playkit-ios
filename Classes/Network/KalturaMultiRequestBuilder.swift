//
//  RestMultiRequestBuilder.swift
//  Pods
//
//  Created by Admin on 13/11/2016.
//
//

import UIKit
import SwiftyJSON

class KalturaMultiRequestBuilder: KalturaRequestBuilder {
    
    var requests: [KalturaRequestBuilder] = [KalturaRequestBuilder]()

    init?(url: String) {
        super.init(url: url, service: "multirequest", action: nil)
    }
    
    @discardableResult
    internal func add(request:KalturaRequestBuilder) -> Self {
        self.requests.append(request)
        return self
    }
    
    override public func build() -> Request {
        
        let data = self.kalturaMultiRequestData()
        let request = RequestElement(requestId: self.requestId, method: self.method, url: self.url, dataBody: data, headers: self.headers, timeout: self.timeout, configuration: self.configuration, responseSerializer: self.responseSerializer, completion: self.completion)
        
        return request
    }
    
    func kalturaMultiRequestData() -> Data? {
        
        if self.jsonBody == nil {
            self.jsonBody = JSON([String: Any]())
        }
        
        for (index, request)  in self.requests.enumerated() {
            if let body = request.jsonBody {
                var singleRequestBody: JSON = body
                singleRequestBody["action"] = JSON(request.action ?? "")
                singleRequestBody["service"] =  JSON(request.service ?? "")
                self.jsonBody?[String(index+1)] = singleRequestBody
            }
        }
        
        let prefix = "{"
        let suffix = "}"
        var data = prefix.data(using: String.Encoding.utf8)
        
        for  index in 1...self.requests.count {
            let requestBody = self.jsonBody?[String(index)].rawString(String.Encoding.utf8, options: JSONSerialization.WritingOptions())?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let requestBodyData = requestBody?.data(using: String.Encoding.utf8)
            data?.append("\"\(index)\":".data(using: String.Encoding.utf8)!)
            data?.append(requestBodyData!)
            data?.append(",".data(using: String.Encoding.utf8)!)
            _ = self.jsonBody?.dictionaryObject?.removeValue(forKey: String(index))
        }
        
        if let jsonBody = self.jsonBody{
            let remainingJsonAsString: String? = jsonBody.rawString(String.Encoding.utf8, options: JSONSerialization.WritingOptions())
            if let jsonString = remainingJsonAsString{
                var jsonWithoutLastChar = String(jsonString.characters.dropLast())
                
                jsonWithoutLastChar = String(jsonWithoutLastChar.characters.dropFirst())
                data?.append((jsonWithoutLastChar.data(using: String.Encoding.utf8))!)
            }
        }
        
        data?.append(suffix.data(using: String.Encoding.utf8)!)
        
        return data
    }
}


