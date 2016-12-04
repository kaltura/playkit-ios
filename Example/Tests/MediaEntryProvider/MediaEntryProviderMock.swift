//
//  MediaEntryProviderMock.swift
//  PlayKit
//
//  Created by Rivka Peleg on 04/12/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import PlayKit



class MediaEntryProviderMockExecutor: RequestExecutor {

    var entryID: String
    var domain: String
    
    init(entryID:String,domain:String) {
        self.entryID = entryID
        self.domain = domain
    }
    
    let serviceKey = "service"
    let actionKey = "action"
    
    
    func send(request:Request){
        
        var fileName = self.domain
        
        let urlComponent = request.url.absoluteString.components(separatedBy: "/")
        
        var serviceName: String? = nil
        var actionName: String? = nil
        
        let serviceKeyIndex = urlComponent.index(of: serviceKey)
        
        if let serviceKeyIndex = serviceKeyIndex{
            serviceName = urlComponent[serviceKeyIndex + 1]
        }
        
        
        let actionKeyIndex = urlComponent.index(of: actionKey)
        if let actionKeyIndex = actionKeyIndex{
            actionName = urlComponent[actionKeyIndex+1]
        }
        
        
        if let service = serviceName{
            fileName.append(".\(service)")
        }
        else{
            fileName.append("._")
        }
        
        
        if let action = actionName{
            fileName.append(".\(action)")
        }
        else{
            fileName.append("._")
        }
        
        fileName.append(".\(entryID)")
        
        
        let bundle = Bundle.main
        let path = bundle.path(forResource: fileName, ofType: "json")
        guard let filePath = path else {
            
            if let completion = request.completion{
                completion(Response(data: nil, error: nil))
            }
            return
        }
        
        let content =  NSData(contentsOfFile:filePath) as Data?
        
        guard let contentFile = content else {
            if let completion = request.completion{
                completion(Response(data: nil, error: nil))
            }
            return
        }
        
        do{
            let result = try JSONSerialization.jsonObject(with: contentFile, options: JSONSerialization.ReadingOptions())
            if let completion = request.completion{
                completion(Response(data: result, error: nil))
            }
            
        }catch{
            if let completion = request.completion{
                completion(Response(data: nil, error: nil))
            }
            
        }
        
    }
    
    func cancel(request:Request){
        
    }
    
    func clean(){
        
    }
}


