//
//  SessionManager.swift
//  Pods
//
//  Created by Admin on 17/11/2016.
//
//

import UIKit

public struct SessionInfo {
    
    public private(set) var udid: String?
    public private(set) var ks: String?
    public private(set) var refreshToken: String?
    public private(set) var tokenExpiration: Date?
}


@objc public protocol OTTSessionManagerDelegate {
    func sessionManagerDidUpdateSession(sender:OTTSessionManager)
}


@objc public class OTTSessionManager: NSObject, SessionProvider {
    
    enum SessionManagerError: Error{
        case failedToGetKS
        case failedToGetLoginResponse
        case failedToRefreshKS
        case failedToBuildRefreshRequest
        case invalidRefreshCallResponse
        case noRefreshTokenOrTokenToRefresh
        case failedToParseResponse
        case failedToLogout
    }
    
    public weak var delegate: OTTSessionManagerDelegate? = nil
    public let saftyMargin = 5*60.0
    
    @objc public var serverURL: String
    @objc public var partnerId: Int64
    
    public var executor: RequestExecutor
    
    public private(set) var sessionInfo: SessionInfo? {
        didSet{
           self.delegate?.sessionManagerDidUpdateSession(sender: self)
        }
    }
    

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
    
    
    func clearSessionData() {
        self.sessionInfo = SessionInfo(udid: nil, ks: nil, refreshToken: nil, tokenExpiration: nil)
    }
    
    @objc public func logout( completion: @escaping (_ error: Error?) -> Void ) {
        
        guard let ks = self.sessionInfo?.ks,
            let udid = self.sessionInfo?.udid else {
                self.clearSessionData()
                completion(nil)
                return
        }
        
        let logoutRequest = OTTUserService.logout(baseURL: self.serverURL, partnerId: self.partnerId, ks: ks, udid: udid)?
        .setOTTBasicParams()
        .set(completion: { (response) in
            completion(response.error != nil ? SessionManagerError.failedToLogout : nil)
           self.clearSessionData()
        }).build()
        
        if let req = logoutRequest{
            self.executor.send(request: req)
        }else{
            self.clearSessionData()
            completion(SessionManagerError.failedToLogout)
        }
        


    }
    
    @objc public func recoverSession(ks:String?, refreshToken: String?, udid: String?, completion: @escaping (_ error: Error?) -> Void ){
        
        self.sessionInfo  = SessionInfo(udid: udid, ks: ks, refreshToken: refreshToken, tokenExpiration: nil)
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
                            
                            self.sessionInfo = SessionInfo(udid: sessionObj.udid, ks: loginObj.loginSession?.ks, refreshToken: loginObj.loginSession?.refreshToken, tokenExpiration: sessionObj.tokenExpiration)
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
                    
                    if let result = result, result.count == 2,
                        let loginSession = result[0] as? OTTLoginSession,
                        let session = result[1] as? OTTSession {
                        self?.sessionInfo = SessionInfo(udid: session.udid, ks: loginSession.ks, refreshToken: loginSession.refreshToken, tokenExpiration: session.tokenExpiration)
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
        if let expiration = self.sessionInfo?.tokenExpiration, expiration.timeIntervalSince(now) > saftyMargin, let ks = self.sessionInfo?.ks {
            completion(ks,nil)
        } else {
            self.refreshKS(completion: completion)
        }
    }
    
    @objc public func refreshKS(completion: @escaping (String?, Error?) -> Void) {
        
        guard let refreshToken = self.sessionInfo?.refreshToken, let ks = self.sessionInfo?.ks , let udid = self.sessionInfo?.udid else {
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
                
                self.sessionInfo = SessionInfo(udid: session.udid, ks: loginSession.ks, refreshToken: loginSession.refreshToken, tokenExpiration: session.tokenExpiration)
                completion(self.sessionInfo?.ks, nil)
                return
            } else {
                self.clearSessionData()
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

