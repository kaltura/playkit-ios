//
//  SessionManager.swift
//  Pods
//
//  Created by Admin on 17/11/2016.
//
//

import UIKit

public class OTTSessionManager: SessionProvider {
    
    
    enum SessionManagerError: Error{
        
        case failedToGetKS
    }
    
    
    public var serverURL: String
    public var partnerId: Int64
    
    public var executor: RequestExecutor?
    
    
    private var sessionInfo: OTTLoginSession?
    
    
    public init(serverURL:String, partnerId:Int64, executor: RequestExecutor?) {
        
        self.serverURL = serverURL
        self.partnerId = partnerId
        self.executor = executor
    }
    
    
    
    
    public func login(username:String, password:String, completion:(_ error:Error?)->Void) -> Void {
        
        let loginRequestBuilder = OTTUserService.login(baseURL: self.serverURL,
                                                       partnerId: partnerId,
                                                       username: username,
                                                       password: password)
        
        let sessionGetRequest = OTTSessionService.get(baseURL: self.serverURL,
                                                      ks:"1:result:loginSession:ks")
        
        if let r1 = loginRequestBuilder, let r2 = sessionGetRequest {
            
            let mrb = OTTMultiRequestBuilder(url: self.serverURL)?.add(request: r1).add(request: r2)
            mrb?.set(completion: { (r:Response) in
                
                if let data = r.data
                {
                    let result: [Result<OTTBaseObject>] = OTTMultiResponseParser.parse(data:data)
                    
                    if result.count == 2{
                        let loginResult: Result<OTTBaseObject> = result[0]
                        let sessionResult: Result<OTTBaseObject> = result[1]
                        
                        
                    }
                    
                    
                }
                
            })
            .build()
            
            if let request = mrb {
                
                if self.executor != nil{
                    self.executor?.send(request: request)
                }else{
                    USRExecutor.shared.send(request: request)
                }
                
            }
        }
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
