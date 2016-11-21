//
//  SessionManager.swift
//  Pods
//
//  Created by Admin on 17/11/2016.
//
//

import UIKit
import SwiftyJSON

public class OTTSessionManager: SessionProvider {
    
    
    enum SessionManagerError: Error{
        
        case failedToGetKS
    }
    
    
    public var serverURL: String
    public var partnerId: Int64
    public var clientTag: String
    public var apiVersion: String

    
    private var sessionInfo: SessionInfo?


    public init(serverURL:String, partnerId:Int64, clientTag:String, apiVersion:String) {
        
        self.serverURL = serverURL
        self.partnerId = partnerId
        self.clientTag = clientTag
        self.apiVersion = apiVersion
    }

    
    public func refreshKS(completion: (Result<String>) -> Void) {
        
    }

    
    public func login(username:String, password:String, completion:(_ error:Error?)->Void) -> Void {
        
        
        let loginRequestBuilder = OTTUserService.login(baseURL: self.serverURL, partnerId: partnerId, username: username, password: password)?.set(completion: { (r:Response) in
            
            if let data: Data = r.data {
                let jsonResponse = JSON(data: data)
                let sessionInfo = SessionInfo(json:jsonResponse.object)
                self.sessionInfo = sessionInfo
            }
        })
        
        if let request = loginRequestBuilder {
                USRExecutor.shared.send(request: loginRequestBuilder!)
        }
        
        
//        let sessionStatusRequestBuilder = OTTSessionService.get(baseURL: self.serverURL, ks: "1:result:loginSession:ks")?.set(completion: { (r:Response) in
//            
//        })
//        
//        
//        USRExecutor.shared.send(request: )
    
    }
    
    
    public func loadKS(completion: (_ result :Result<String>) -> Void) {
        
        if let refreshToken = sessionInfo?.refreshToken {
         
            let requestBuilder = OTTUserService.refreshSession(baseURL: self.serverURL, refreshToken: refreshToken)?.set(completion: { (r:Response) in
                r.statusCode
                
            })
            
        }else{
            
            if let ks = self.sessionInfo?.ks{
                completion(Result(data: ks, error: nil))
            }else{
                completion(Result(data: nil, error: SessionManagerError.failedToGetKS))
            }
        }
        
        
    }
    
    
    public func test () {
        
    }



}
