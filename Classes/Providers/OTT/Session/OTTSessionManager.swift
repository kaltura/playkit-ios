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
        case failedToGetLoginResponse
    }
    
    
    public var serverURL: String
    public var partnerId: Int64
    
    public var executor: RequestExecutor?
    
    
    private var ks: String?
    private var refreshToken: String?
    private var tokenExpiration: Date?
    
    
    public init(serverURL:String, partnerId:Int64, executor: RequestExecutor?) {
        
        self.serverURL = serverURL
        self.partnerId = partnerId
        self.executor = executor
    }
    
    
    
    
    public func login(username:String, password:String, completion:@escaping (_ error:Error?)->Void) -> Void {
        
        let loginRequestBuilder = OTTUserService.login(baseURL: self.serverURL,
                                                       partnerId: partnerId,
                                                       username: username,
                                                       password: password)
        
        let sessionGetRequest = OTTSessionService.get(baseURL: self.serverURL,
                                                      ks:"1:result:loginSession:ks")
        
        if let r1 = loginRequestBuilder, let r2 = sessionGetRequest {
            
            let mrb = KalturaMultiRequestBuilder(url: self.serverURL)?.add(request: r1).add(request: r2)
            mrb?.set(completion: { (r:Response) in
                
                if let data = r.data
                {
                    let result: [Result<OTTBaseObject>] = OTTMultiResponseParser.parse(data:data)
                    
                    if result.count == 2{
                        let loginResult: Result<OTTBaseObject> = result[0]
                        let sessionResult: Result<OTTBaseObject> = result[1]
                        
                        if  let obj1 = loginResult.data , let obj2 = sessionResult.data, let loginObj = obj1 as? OTTLogin, let sessionObj = obj2 as? OTTSession  {
                        
                            self.ks = loginObj.ks
                            self.refreshToken = loginObj.refreshToken
                            self.tokenExpiration = sessionObj.tokenExpiration
                            
                        }
                        completion(nil)
                    }else{
                        completion(SessionManagerError.failedToGetLoginResponse)
                    }
                }else{
                  completion(SessionManagerError.failedToGetLoginResponse)
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
        
        
        let now = Date()
        
        if let expiration = self.tokenExpiration, expiration.timeIntervalSince(now) < 5.0*60 {
            completion(Result(data:self.ks, error: nil))
        }else{
            
            if let refreshToken = self.refreshToken, let ks = self.ks{
                let refreshSessionRequest = OTTUserService.refreshSession(baseURL: self.serverURL, refreshToken: refreshToken, ks:ks )
                let getSessionRequest = OTTSessionService.get(baseURL: self.serverURL, ks: "1:result:loginSession:ks")
                
                if let req1 = refreshSessionRequest, let req2 = getSessionRequest {
                    
                }
                    let mrb: KalturaMultiRequestBuilder? = ((KalturaMultiRequestBuilder(url: self.serverURL)?.add(request: refreshSessionRequest!).add(request: getSessionRequest!))?.set(completion: { (r:Response) in
                        
                        if let data = r.data{
                            OTTMultiResponseParser.parse(data: data)
                        }
                        
                    }))

                
                
                if let request = mrb {
                    
                    if self.executor != nil{
                        self.executor?.send(request: request)
                    }else{
                        USRExecutor.shared.send(request: request)
                    }
                    
                }

            }
        }
            
    }
    
    
//    if let data = r.data{
//        let response: Result<OTTBaseObject> = OTTResponseParser.parse(data: r.data)
//        if let data = response.data, let refreshedSession = data as? OTTRefreshedSession {
//            self.ks = refreshedSession.ks
//            self.refreshToken = refreshedSession.refreshToken
//        }
//    }

    

    
    
}
