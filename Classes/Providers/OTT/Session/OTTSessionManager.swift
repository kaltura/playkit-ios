//
//  SessionManager.swift
//  Pods
//
//  Created by Admin on 17/11/2016.
//
//

import UIKit

@objc public class OTTSessionManager: NSObject, SessionProvider {
    
    enum SessionManagerError: Error{
        case failedToGetKS
        case failedToGetLoginResponse
        case failedToRefreshKS
        case failedToBuildRefreshRequest
        case invalidRefreshCallResponse
        case noRefreshTokenOrTokenToRefresh
        case failedToParseResponse
    }
    
    public let saftyMargin = 5*60.0
    
    @objc public var serverURL: String
    @objc public var partnerId: Int64
    public var executor: RequestExecutor
    
    public private(set) var udid: String?
    public private(set) var ks: String?
    public private(set) var refreshToken: String?
    private var tokenExpiration: Date?
    
    
    
    public init(serverURL: String, partnerId: Int64, executor: RequestExecutor?) {
        self.serverURL = serverURL
        self.partnerId = partnerId
        if let exe = executor{
            self.executor = exe
        } else {
            self.executor = USRExecutor.shared
        }
    }
    
    @objc public convenience init(serverURL: String, partnerId: Int64) {
        self.init(serverURL: serverURL, partnerId: partnerId, executor: nil)
    }
    
    @objc public func logout() {

        self.ks = nil
        self.refreshToken = nil
        self.tokenExpiration = nil
        self.udid = nil

    }
    
    @objc public func recoverSession(ks:String, refreshToken: String, udid: String, completion: @escaping (_ error: Error?) -> Void ){
        self.ks = ks
        self.refreshToken = refreshToken
        self.udid = udid
        self.refreshKS { (ks, error) in
            completion(error)
        }
    }
    
    
    @objc public func startSession(token:String,type:KalturaSocialNetwork,udid:String, completion: @escaping (_ error: Error?) -> Void) {
        
        let loginRequestBuilder = OTTSocialService.login(baseURL: self.serverURL,
                                                         partner: Int(partnerId),
                                                         token: token,
                                                         type: type,
                                                         udid: udid)
        
        let sessionGetRequest = OTTSessionService.get(baseURL: self.serverURL,
                                                      ks:"{1:result:loginSession:ks}")
        
        if let req1 = loginRequestBuilder, let req2 = sessionGetRequest {
            if let mrb = KalturaMultiRequestBuilder(url: self.serverURL)?.add(request: req1).add(request: req2) {
                self.startSession(request: mrb, completion: completion)
            }else{
                completion(SessionManagerError.failedToGetLoginResponse)
            }
        }else{
            completion(SessionManagerError.failedToGetLoginResponse)
        }
        
    }
    
    @objc public func startSession(username: String, password: String, udid: String, completion: @escaping (_ error: Error?) -> Void) -> Void {
        
        let loginRequestBuilder = OTTUserService.login(baseURL: self.serverURL,
                                                       partnerId: partnerId,
                                                       username: username,
                                                       password: password,
                                                       udid: udid)
        
        let sessionGetRequest = OTTSessionService.get(baseURL: self.serverURL,
                                                      ks:"{1:result:loginSession:ks}")
        
        if let req1 = loginRequestBuilder, let req2 = sessionGetRequest {
            if let mrb = KalturaMultiRequestBuilder(url: self.serverURL)?.add(request: req1).add(request: req2) {
                self.startSession(request: mrb, completion: completion)
            }else{
                completion(SessionManagerError.failedToGetLoginResponse)
            }
        }else{
            completion(SessionManagerError.failedToGetLoginResponse)
        }
    }
    
    private func startSession(request:KalturaMultiRequestBuilder,completion: @escaping (_ error: Error?) -> Void){
    
            request.setOTTBasicParams()
            request.set(completion: { (r:Response) in
                
                if let data = r.data {
                    var result: [OTTBaseObject]? = nil
                    do {
                        result = try OTTMultiResponseParser.parse(data:data)
                    } catch {
                        completion(error)
                    }
                    
                    if let result = result, result.count == 2{
                        let loginResult: OTTBaseObject = result[0]
                        let sessionResult: OTTBaseObject = result[1]
                        
                        if  let loginObj = loginResult as? OTTLoginResponse, let sessionObj = sessionResult as? OTTSession  {
                            
                            self.ks = loginObj.loginSession?.ks
                            self.refreshToken = loginObj.loginSession?.refreshToken
                            self.tokenExpiration = sessionObj.tokenExpiration
                            self.udid = sessionObj.udid
                        }
                        completion(nil)
                    } else {
                        completion(SessionManagerError.failedToGetLoginResponse)
                    }
                } else {
                    completion(SessionManagerError.failedToGetLoginResponse)
                }
            })
            
            let request = request.build()
            self.executor.send(request: request)
    }
    

    
    @objc public func startAnonymousSession(completion:@escaping (_ error: Error?) -> Void) {
        
        let loginRequestBuilder = OTTUserService.anonymousLogin(baseURL: self.serverURL,
                                                                partnerId: self.partnerId)
        let sessionGetRequest = OTTSessionService.get(baseURL: self.serverURL, ks: "{1:result:ks}")
        
        if let r1 = loginRequestBuilder, let r2 = sessionGetRequest {
            
            let mrb = KalturaMultiRequestBuilder(url: self.serverURL)?.add(request: r1)
                .setOTTBasicParams()
                .add(request: r2).setOTTBasicParams()
                .set(completion: { [weak self] (r:Response)  in
                
                if let data = r.data
                {
                    var result: [OTTBaseObject]? = nil
                    do {
                      result = try OTTMultiResponseParser.parse(data:data)
                    } catch {
                        completion(error)
                    }
                    
                    if let result = result, result.count == 2, let loginSession = result[0] as? OTTLoginSession, let session = result[1] as? OTTSession{
                        
                        self?.ks = loginSession.ks
                        self?.refreshToken = loginSession.refreshToken
                        self?.tokenExpiration = session.tokenExpiration
                        self?.udid = session.udid
                        completion(nil)
                    } else {
                        completion(SessionManagerError.failedToGetLoginResponse)
                    }
                } else {
                    completion(SessionManagerError.failedToGetLoginResponse)
                }
            })
            
            if let request = mrb?.build() {
                self.executor.send(request: request)
            }
        }
    }
    
    @objc public func loadKS(completion: @escaping (String?, Error?) -> Void) {
        
        let now = Date()
        if let expiration = self.tokenExpiration, expiration.timeIntervalSince(now) > saftyMargin {
            completion(self.ks, nil)
        } else {
            self.refreshKS(completion: completion)
        }
    }
    
    @objc public func refreshKS(completion: @escaping (String?, Error?) -> Void) {
        
        guard let refreshToken = self.refreshToken, let ks = self.ks , let udid = self.udid else {
            completion(nil, SessionManagerError.noRefreshTokenOrTokenToRefresh)
            return
        }
        
        let refreshSessionRequest = OTTUserService.refreshSession(baseURL: self.serverURL, refreshToken: refreshToken, ks: ks, udid: udid)
        let getSessionRequest = OTTSessionService.get(baseURL: self.serverURL, ks: "{1:result:ks}")
        
        guard let req1 = refreshSessionRequest, let req2 = getSessionRequest else {
            completion(nil, SessionManagerError.invalidRefreshCallResponse)
            return
        }
        
        let mrb: KalturaMultiRequestBuilder? = (KalturaMultiRequestBuilder(url: self.serverURL)?.add(request: req1).add(request: req2))?.setOTTBasicParams().set(completion: { (r:Response) in
            
            guard let data = r.data else {
                completion(nil, SessionManagerError.failedToRefreshKS)
                return
            }
            
            var response: [OTTBaseObject]? = nil
            do {
                response = try OTTMultiResponseParser.parse(data: data)
            } catch {
                completion(nil, error)
                return
            }
            
            if let response = response, response.count == 2, let loginSession = response[0] as? OTTLoginSession, let session = response[1] as? OTTSession {
                
                self.ks = loginSession.ks
                self.refreshToken = loginSession.refreshToken
                self.tokenExpiration = session.tokenExpiration
                self.udid = session.udid
                completion(self.ks, nil)
                return
            } else {
                self.logout()
                completion(nil, SessionManagerError.failedToRefreshKS)
                return
            }
        })
        
        if let request = mrb?.build() {
            self.executor.send(request: request)
        } else {
            completion(nil, SessionManagerError.failedToBuildRefreshRequest)
            return
        }
    }
}

