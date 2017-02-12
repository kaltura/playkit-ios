//
//  OVPSessionManager.swift
//  Pods
//
//  Created by Rivka Peleg on 29/12/2016.
//
//

import UIKit

public class OVPSessionManager: SessionProvider {
    
    
    public enum SessionManagerError: Error{
        
        case failedToGetKS
        case failedToGetLoginResponse
        case failedToRefreshKS
        case failedToBuildRefreshRequest
        case invalidRefreshCallResponse
        case noRefreshTokenOrTokenToRefresh
        case failedToParseResponse
        case ksExpired
        
    }
    
    public var serverURL: String
    public var partnerId: Int64
    
    private var executor: RequestExecutor
    private var version: String
    private var fullServerPath: String
    
    private var ks: String? = nil
    private var tokenExpiration: Date?

    
    private var username: String?
    private var password: String?
    
    
    private let defaultSessionExpiry = TimeInterval(24*60*60)
    
    public init(serverURL: String, partnerId: Int64, executor: RequestExecutor? = nil) {
        self.serverURL = serverURL
        self.partnerId = partnerId
        self.version = "api_v3"
        self.fullServerPath = self.serverURL.appending("/\(self.version)")
        
        if let exe  = executor {
            self.executor = exe
        }else{
            self.executor = USRExecutor.shared
        }
    }
        
    @available(*, deprecated, message: "Use init(serverURL:partnerId:executor:)")
    public convenience init(serverURL: String, version:String, partnerId: Int64, executor: RequestExecutor?) {
        self.init(serverURL: serverURL, partnerId: partnerId, executor: executor)
    }
    
    public func loadKS(completion: @escaping (_ result :Result<String>) -> Void){
        if let ks = self.ks, self.tokenExpiration?.compare(Date()) == ComparisonResult.orderedDescending {
                completion(Result(data: ks))
        }else{
            
            self.ks = nil
            if let username = self.username,
                let password = self.password {
                
                self.startSession(username: username,
                                  password: password, completion: { (e:Error?) in
                                    self.ensureKSAfterRefresh(e: e, completion: completion)
                })
            }
            else{
                
                self.startAnonymouseSession(completion: { (e:Error?) in
                    self.ensureKSAfterRefresh(e: e, completion: completion)
                })
            }
            
            
        }
        
    }
    
    
    func ensureKSAfterRefresh(e:Error?,completion: @escaping (_ result :Result<String>) -> Void) -> Void {
        if let ks = self.ks {
            completion(Result(data: ks))
        }else if let error = e {
            completion(Result(error: error))
        }else{
            completion(Result(error: SessionManagerError.ksExpired))
        }
    }
    
    

    
    // FIXME: Anonymous, no e
    public func startAnonymouseSession(completion:@escaping (_ error:Error?)->Void) -> Void {
        
        let loginRequestBuilder = OVPSessionService.startWidgetSession(baseURL: self.fullServerPath,
                                                                       partnerId: self.partnerId)?
        
        
            .setOVPBasicParams()
            .set(completion: { (r:Response) in
                
                if let data = r.data
                {
                    var result: OVPBaseObject? = nil
                    do{
                        result = try OVPResponseParser.parse(data:data)
                        if let widgetSession = result as? OVPStartWidgetSessionResponse {
                            self.ks = widgetSession.ks
                            self.tokenExpiration = Date(timeIntervalSinceNow:self.defaultSessionExpiry )
                            completion(nil)
                            
                        }else{
                            completion(SessionManagerError.failedToGetKS)
                        }
                        
                    }catch{
                        completion(error)
                    }
                }else{
                    completion(SessionManagerError.failedToGetLoginResponse)
                }
                
                
            })
            
            
            if let request = loginRequestBuilder?.build() {
                self.executor.send(request: request)
            }
    }


    
    public func startSession(username:String,password:String,completion:@escaping (_ error:Error?)->Void) -> Void {
        
        self.username = username
        self.password = password
        
        let loginRequestBuilder = OVPUserService.loginByLoginId(baseURL: self.fullServerPath,
                                                                loginId: username,
                                                                password: password,
                                                                partnerId: self.partnerId)
        
        let sessionGetRequest = OVPSessionService.get(baseURL: self.fullServerPath,
                                                      ks:"{1:result}")
        
        if let r1 = loginRequestBuilder, let r2 = sessionGetRequest {
            
            let mrb = KalturaMultiRequestBuilder(url: self.fullServerPath)?.add(request: r1).add(request: r2).setOVPBasicParams()
            mrb?.set(completion: { (r:Response) in
                
                if let data = r.data
                {
                    do{
                        
                        guard   let arrayResult = data as? [Any],
                                arrayResult.count == 2
                        else {
                             completion(SessionManagerError.failedToParseResponse)
                            return
                        }
                        
                        let sessionInfo = OVPKalturaSessionInfo(json: arrayResult[1])
                        self.ks = arrayResult[0] as? String
                        self.tokenExpiration = sessionInfo?.expiry
                        completion(nil)
                    }catch{
                        completion(error)
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
}
