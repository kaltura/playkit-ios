//
//  URLSessionRequestExecutor.swift
//  Pods
//
//  Created by Admin on 10/11/2016.
//
//

import UIKit

public class URLSessionRequestExecutor : RequestExecutor {

    
    public init(){
        
    }
    
    public func send(request:Request){
        
        let url = request.url
        let task = URLSession.shared.dataTask(with: url!) {(data, response, error) in
            if let completion = request.completion {
                
                let result = Response(data: data, error:nil)
                completion(result)
            }
        }
        task.resume()
    }
    
    public func cancel(request:Request){
        
    }
    
    public func clean(){
        
    }

}
