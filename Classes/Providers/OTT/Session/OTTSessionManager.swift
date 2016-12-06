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
        case failedToRefreshKS
        case failedToBuildRefreshRequest
        case invalidRefreshCallResponse
        case noRefreshTokenOrTokenToRefresh
        case failedToParseResponse
    }
    
    
    let saftyMargin = 5*60.0
    
    public var serverURL: String
    public var partnerId: Int64
    public var executor: RequestExecutor
    
    
    private var ks: String?
    private var refreshToken: String?
    private var tokenExpiration: Date?
    
    
    
    public init(serverURL:String, partnerId:Int64, executor: RequestExecutor?) {
        
        self.serverURL = serverURL
        self.partnerId = partnerId
        if let exe = executor{
            self.executor = exe
        }else{
            self.executor = USRExecutor.shared
        }
    }
    
    
    public func startSession(username:String, password:String, completion:@escaping (_ error:Error?)->Void) -> Void {
        
        let loginRequestBuilder = OTTUserService.login(baseURL: self.serverURL,
                                                       partnerId: partnerId,
                                                       username: username,
                                                       password: password)
        
        let sessionGetRequest = OTTSessionService.get(baseURL: self.serverURL,
                                                      ks:"1:result:loginSession:ks")
        
        if let r1 = loginRequestBuilder, let r2 = sessionGetRequest {
            
            let mrb = KalturaMultiRequestBuilder(url: self.serverURL)?.add(request: r1).add(request: r2).setOTTBasicParams()
            mrb?.set(completion: { (r:Response) in
                
                if let data = r.data
                {
                     let result: [OTTBaseObject]? = nil
                    do{
                        let result: [OTTBaseObject] = try OTTMultiResponseParser.parse(data:data)
                    }catch{
                        completion(error)
                    }
                    
                    if let result = result, result.count == 2{
                        let loginResult: OTTBaseObject = result[0]
                        let sessionResult: OTTBaseObject = result[1]
                        
                        if  let loginObj = loginResult as? OTTLoginResponse, let sessionObj = sessionResult as? OTTSession  {
                            
                            self.ks = loginObj.loginSession?.ks
                            self.refreshToken = loginObj.loginSession?.refreshToken
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
            
            
            if let request = mrb?.build() {
                self.executor.send(request: request)
            }
        }
    }
    
    public func startAnonymouseSession(completion:@escaping (_ error:Error?)->Void) {
        
        let loginRequestBuilder = OTTUserService.anonymousLogin(baseURL: self.serverURL,
                                                                partnerId: self.partnerId)
        let sessionGetRequest = OTTSessionService.get(baseURL: self.serverURL,
                                                      ks:"1:result:ks")
        
        
        if let r1 = loginRequestBuilder, let r2 = sessionGetRequest {
            
            let mrb = KalturaMultiRequestBuilder(url: self.serverURL)?.add(request: r1)
                .setOTTBasicParams()
                .add(request: r2).setOTTBasicParams()
                .set(completion: { (r:Response) in
                
                if let data = r.data
                {
                    var result: [OTTBaseObject]? = nil
                    do{
                      result = try OTTMultiResponseParser.parse(data:data)
                    }catch{
                        completion(error)
                    }
                    
                    if let result = result, result.count == 2, let loginSession = result[0] as? OTTLoginSession, let session = result[1] as? OTTSession{
                        
                        self.ks = loginSession.ks
                        self.refreshToken = loginSession.refreshToken
                        self.tokenExpiration = session.tokenExpiration
                        completion(nil)
                    }else{
                        completion(SessionManagerError.failedToGetLoginResponse)
                    }
                    
                }else{
                    completion(SessionManagerError.failedToGetLoginResponse)
                }

            })
            
            
            if let request = mrb?.build() {
                self.executor.send(request: request)
            }
        }
        
        
        
        
        
        
    }
    
    
    public func loadKS(completion: @escaping (_ result :Result<String>) -> Void) {
        let now = Date()
        
        if let expiration = self.tokenExpiration, expiration.timeIntervalSince(now) > saftyMargin {
            completion(Result(data:self.ks, error: nil))
        }else{
            
            self.refreshKS(completion: completion)
        }
    }
    
    public func refreshKS(completion: @escaping (_ result :Result<String>) -> Void){
        
        if let refreshToken = self.refreshToken, let ks = self.ks{
            
            let refreshSessionRequest = OTTUserService.refreshSession(baseURL: self.serverURL, refreshToken: refreshToken, ks:ks )
            let getSessionRequest = OTTSessionService.get(baseURL: self.serverURL, ks: "1:result:ks")
            
            if let req1 = refreshSessionRequest, let req2 = getSessionRequest {
                
                let mrb: KalturaMultiRequestBuilder? = ((KalturaMultiRequestBuilder(url: self.serverURL)?.add(request: req1).add(request: req2))?.setOTTBasicParams().set(completion: { (r:Response) in
                    
                    if let data = r.data{
                        let response: [OTTBaseObject]? = nil
                        do{
                        let response: [OTTBaseObject] = try OTTMultiResponseParser.parse(data: data)
                        }catch{
                            completion(Result(data: nil, error: error))
                        }
                        
                        if let response = response, response.count == 2, let loginSession = response[0] as? OTTLoginSession, let session = response[1] as? OTTSession{
                            
                            self.ks = loginSession.ks
                            self.refreshToken = loginSession.refreshToken
                            self.tokenExpiration = session.tokenExpiration
                            
                            completion(Result(data: self.ks, error: nil))
                            
                        }else{
                            completion(Result(data: nil, error: SessionManagerError.failedToRefreshKS))
                        }
                        
                    }else{
                        completion(Result(data: nil, error: SessionManagerError.failedToRefreshKS))
                    }
                    
                }))
                
                if let request = mrb?.build() {
                    self.executor.send(request: request)
                    
                }else{
                    completion(Result(data: nil, error: SessionManagerError.failedToBuildRefreshRequest))
                }
                
            }else{
               completion(Result(data: nil, error: SessionManagerError.invalidRefreshCallResponse))
            }
        }else{
            completion(Result(data: nil, error: SessionManagerError.noRefreshTokenOrTokenToRefresh))
        }

    }
    
    
    
    
    
    
    
}
