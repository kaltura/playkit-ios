//
//  RestMultiRequestBuilder.swift
//  Pods
//
//  Created by Admin on 13/11/2016.
//
//

import UIKit
import SwiftyJSON

internal class OTTMultiRequestBuilder: OTTRequestBuilder {
    
    internal var requests: [OTTRequestBuilder] = [OTTRequestBuilder]()

    internal init?(url: String) {
        super.init(url: url, service: "multiRequest", action: nil)
        
        
    }
    
    internal func add(request:OTTRequestBuilder) -> Self {
        
        self.requests.append(request)
        return self
    }
    override public func build() -> Request {
        super.build()
        
        
        
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
                self.jsonBody?.dictionaryObject?.removeValue(forKey: String(index))
            }catch{
                
            }
        }
        
        String.init("test".characters.dropFirst())
        do{
            
            if let jsonBody = self.jsonBody{
                var remainingJsonAsString: String? = jsonBody.rawString(String.Encoding.utf8, options: JSONSerialization.WritingOptions())
                if let jsonString = remainingJsonAsString{
                    var jsonWithoutLastChar = String(jsonString.characters.dropLast())
                    if  jsonWithoutLastChar != nil{
                        jsonWithoutLastChar = String(jsonWithoutLastChar.characters.dropFirst())
                        data?.append((jsonWithoutLastChar.data(using: String.Encoding.utf8))!)
                    }
                    
                }
                
                
                
            }
        }catch{
            print("unable to parse json")
        }
        
        data?.append(suffix.data(using: String.Encoding.utf8)!)
        self.dataBody = data
        //    let string = String(data: data!, encoding: String.Encoding.utf8)
        //    print(string)
        
        
        return self
    }
}
