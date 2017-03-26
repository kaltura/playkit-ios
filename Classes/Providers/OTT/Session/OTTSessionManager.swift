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
    func sessionManagerDidUpdateSession(sender: OTTSessionManager)
}

@objc public class OTTSessionManager: NSObject, SessionProvider {

    enum SessionManagerError: Error {
        case failed
        case failedToGetLoginResponse
        case failedToRefreshKS
        case failedToLogout
    }

    public weak var delegate: OTTSessionManagerDelegate?
    public var saftyMargin: TimeInterval = 0

    @objc public var serverURL: String
    @objc public var partnerId: Int64

    public var executor: RequestExecutor

    public private(set) var sessionInfo: SessionInfo? {
        didSet {
           self.delegate?.sessionManagerDidUpdateSession(sender: self)
        }
    }

    /************************************************************/
    // MARK: - initialization
    /************************************************************/
    public init(serverURL: String, partnerId: Int64, executor: RequestExecutor?) {
        self.serverURL = serverURL
        self.partnerId = partnerId
        if let exe = executor {
            self.executor = exe
        } else {
            self.executor = USRExecutor.shared
        }
    }

    @objc public convenience init(serverURL: String, partnerId: Int64) {
        self.init(serverURL: serverURL, partnerId: partnerId, executor: nil)
    }

    /************************************************************/
    // MARK: - clearSessionData
    /************************************************************/
    func clearSessionData() {
        self.sessionInfo = SessionInfo(udid: nil, ks: nil, refreshToken: nil, tokenExpiration: nil)
    }

    /************************************************************/
    // MARK: - loadKS
    /************************************************************/
    @objc public func loadKS(completion: @escaping (String?, Error?) -> Void) {

        let now = Date()
        if let expiration = self.sessionInfo?.tokenExpiration, expiration.timeIntervalSince(now) > saftyMargin, let ks = self.sessionInfo?.ks {
            completion(ks, nil)
        } else {
            self.refreshKS(completion: completion)
        }
    }

    /************************************************************/
    // MARK: - Logout
    /************************************************************/
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

        if let req = logoutRequest {
            self.executor.send(request: req)
        } else {
            self.clearSessionData()
            completion(SessionManagerError.failedToLogout)
        }

    }

    /************************************************************/
    // MARK: - recover session
    /************************************************************/
    @objc public func recoverSession(ks: String?, refreshToken: String?, udid: String?, completion: @escaping (_ error: Error?) -> Void ) {

        self.sessionInfo  = SessionInfo(udid: udid, ks: ks, refreshToken: refreshToken, tokenExpiration: nil)
        self.refreshKS { (_, error) in
            completion(error)
        }
    }

    /************************************************************/
    // MARK: - start session with user name and password
    /************************************************************/
    @objc public func startSession(username: String, password: String, udid: String, completion: @escaping (_ error: Error?) -> Void) {

        do {
            let startSessionRequests = try self.getStartSessionWithUsernameRequestBuilder(username: username, password: password, udid: udid)
            self.executeSessionRequests(request: startSessionRequests, completion: completion)

        } catch {
            completion(SessionManagerError.failedToGetLoginResponse)
        }
    }

    func getStartSessionWithUsernameRequestBuilder(username: String, password: String, udid: String) throws -> KalturaMultiRequestBuilder {

        let loginRequestBuilder = OTTUserService.login(baseURL: self.serverURL,
                                                       partnerId: partnerId,
                                                       username: username,
                                                       password: password,
                                                       udid: udid)

        let sessionGetRequest = OTTSessionService.get(baseURL: self.serverURL,
                                                      ks:"{1:result:loginSession:ks}")

        if let req1 = loginRequestBuilder, let req2 = sessionGetRequest {
            if let mrb = KalturaMultiRequestBuilder(url: self.serverURL)?
                .add(request: req1)
                .add(request: req2) {
                return mrb
            } else {
                throw SessionManagerError.failed
            }
        } else {
            throw SessionManagerError.failed
        }
    }

    /************************************************************/
    // MARK: - start session with token
    /************************************************************/
    @objc public func startSession(token: String, type: KalturaSocialNetwork, udid: String, completion: @escaping (_ error: Error?) -> Void) {

        do {
            let startSessionRequests = try self.getStartSessionWithTokenRequestBuilder(token: token, type: type, udid: udid)
            self.executeSessionRequests(request: startSessionRequests, completion: completion)

        } catch {
           completion(SessionManagerError.failedToGetLoginResponse)
        }

    }

    func getStartSessionWithTokenRequestBuilder(token: String, type: KalturaSocialNetwork, udid: String) throws -> KalturaMultiRequestBuilder {

        let loginRequestBuilder = OTTSocialService.login(baseURL: self.serverURL,
                                                         partner: Int(partnerId),
                                                         token: token,
                                                         type: type,
                                                         udid: udid)

        let sessionGetRequest = OTTSessionService.get(baseURL: self.serverURL,
                                                      ks:"{1:result:loginSession:ks}")

        if let req1 = loginRequestBuilder, let req2 = sessionGetRequest {
            if let mrb = KalturaMultiRequestBuilder(url: self.serverURL)?
                .add(request: req1)
                .add(request: req2) {
                return mrb
            } else {
                throw SessionManagerError.failed
            }
        } else {
            throw SessionManagerError.failed
        }

    }

    /************************************************************/
    // MARK: - switchUser
    /************************************************************/
     func getswitchUserRequestBuilder(userId: String, ks: String, udid: String) throws -> KalturaMultiRequestBuilder {

        let switchUserRequest = OTTSessionService.switchUser(baseURL: self.serverURL, ks: ks, userId: userId)
        let getSessionRequest = OTTSessionService.get(baseURL: self.serverURL, ks: "{1:result:ks}")

        guard let req1 = switchUserRequest,
            let req2 = getSessionRequest else {
                throw SessionManagerError.failed
        }

        guard let mrb: KalturaMultiRequestBuilder = (KalturaMultiRequestBuilder(url: self.serverURL)?.add(request: req1).add(request: req2)) else {
            throw SessionManagerError.failed
        }

        return mrb

    }

    @objc public func switchUser(userId: String, udid: String, completion: @escaping (_ error: Error?) -> Void) {

        self.loadKS { (ks, _) in

            guard let token = ks else {
                completion(SessionManagerError.failedToRefreshKS)
                return
            }

            do {
                let mbr = try self.getswitchUserRequestBuilder(userId: userId, ks: token, udid: udid)
                self.executeSessionRequests(request: mbr, completion:completion)

            } catch {
                completion(SessionManagerError.failed)
            }
        }
    }

    /************************************************************/
    // MARK: - startAnonymousSession
    /************************************************************/

    func getStartAnonymousSessionRequestBuilder() throws -> KalturaMultiRequestBuilder {
        let loginRequestBuilder = OTTUserService.anonymousLogin(baseURL: self.serverURL,
                                                                partnerId: self.partnerId)
        let sessionGetRequest = OTTSessionService.get(baseURL: self.serverURL, ks: "{1:result:ks}")

        guard let r1 = loginRequestBuilder, let r2 = sessionGetRequest else {
            throw SessionManagerError.failed
        }

        guard let mrb = KalturaMultiRequestBuilder(url: self.serverURL)?.add(request: r1)
            .setOTTBasicParams()
            .add(request: r2) else {
                throw SessionManagerError.failed
        }

        return mrb
    }

    @objc public func startAnonymousSession(completion:@escaping (_ error: Error?) -> Void) {

        do {
            let mbr = try self.getStartAnonymousSessionRequestBuilder()
            self.executeSessionRequests(request: mbr, completion:completion)

        } catch {
            completion(SessionManagerError.failed)
        }
    }

    /************************************************************/
    // MARK: - refreshKS
    /************************************************************/

    func getRefreshKSRequestBuilder() throws -> KalturaMultiRequestBuilder {

        guard let refreshToken = self.sessionInfo?.refreshToken, let ks = self.sessionInfo?.ks, let udid = self.sessionInfo?.udid else {
            throw SessionManagerError.failed
        }

        let refreshSessionRequest = OTTUserService.refreshSession(baseURL: self.serverURL, refreshToken: refreshToken, ks: ks, udid: udid)
        let getSessionRequest = OTTSessionService.get(baseURL: self.serverURL, ks: "{1:result:ks}")

        guard let req1 = refreshSessionRequest, let req2 = getSessionRequest else {
            throw SessionManagerError.failed
        }

        let mrb: KalturaMultiRequestBuilder? = (KalturaMultiRequestBuilder(url: self.serverURL)?.add(request: req1).add(request: req2))

        guard let request = mrb else {
            throw SessionManagerError.failed
        }

        return request

    }

    @objc public func refreshKS(completion: @escaping (String?, Error?) -> Void) {

        do {
            let mbr = try self.getRefreshKSRequestBuilder()
            self.executeSessionRequests(request: mbr, completion: { (error) in
                if( error == nil ) {
                    completion(self.sessionInfo?.ks, nil)
                } else {
                    self.clearSessionData()
                    completion(nil, SessionManagerError.failedToRefreshKS)
                }
            })

        } catch {
            self.clearSessionData()
            completion(nil, SessionManagerError.failedToRefreshKS)

        }

    }

    /************************************************************/
    // MARK: - execute all session request and parse them
    /************************************************************/
    private func executeSessionRequests(request: KalturaMultiRequestBuilder, completion: @escaping (_ error: Error?) -> Void) {

            request.setOTTBasicParams()
            request.set(completion: { (r: Response) in

                if let data = r.data {
                    var result: [OTTBaseObject]? = nil
                    do {
                        result = try OTTMultiResponseParser.parse(data:data)
                    } catch {
                        completion(error)
                    }

                    if let result = result, result.count == 2 {
                        let loginResult: OTTBaseObject = result[0]
                        let sessionResult: OTTBaseObject = result[1]

                        if  let loginObj = loginResult as? OTTLoginResponse,
                            let sessionObj = sessionResult as? OTTSession {

                            self.sessionInfo = SessionInfo(udid: sessionObj.udid, ks: loginObj.loginSession?.ks, refreshToken: loginObj.loginSession?.refreshToken, tokenExpiration: sessionObj.tokenExpiration)
                            completion(nil)
                        } else if  let loginObj = loginResult as? OTTLoginSession,
                            let sessionObj = sessionResult as? OTTSession {

                            self.sessionInfo = SessionInfo(udid: sessionObj.udid, ks: loginObj.ks, refreshToken: loginObj.refreshToken, tokenExpiration: sessionObj.tokenExpiration)
                            completion(nil)
                        } else {
                          completion(SessionManagerError.failed)
                        }

                    } else {
                        completion(SessionManagerError.failed)
                    }
                } else {
                    completion(SessionManagerError.failed)
                }
            })

            let request = request.build()
            self.executor.send(request: request)
    }

}
