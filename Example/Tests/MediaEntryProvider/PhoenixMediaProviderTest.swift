//
//  PhoenixMediaProviderTest.swift
//  PlayKit
//
//  Created by Rivka Peleg on 04/12/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import XCTest
import PlayKit
import KalturaNetKit
import Quick
import Nimble

class PhoenixMediaProviderTest: QuickSpec, SessionProvider {
    
    /************************************************************/
    // MARK: - Mocks
    /************************************************************/
    
    fileprivate class RequestExecutorMock: RequestExecutor {
        
        let onRequestSend: (Request) -> Void
        
        init(onRequestSend: @escaping (Request) -> Void) {
            self.onRequestSend = onRequestSend
        }
        
        func send(request: Request) {
            onRequestSend(request)
        }
        
        func cancel(request: Request) {}
        func clean() {}
    }
    
    /************************************************************/
    // MARK: - SessionProvider
    /************************************************************/
    
    let mediaID = "485293"
    var partnerId: Int64 = 198
    var serverURL: String  = "http://api-preprod.ott.kaltura.com/v4_2/api_v3"
    
    public func loadKS(completion: @escaping (String?, Error?) -> Void) {
        completion(nil, nil)
    }
    
    /************************************************************/
    // MARK: - Tests
    /************************************************************/
    
    override func spec() {
        describe("PhoenixMediaProviderTest") {
            it("should make a request") {
                let expectedUrl = URL(string: "http://api-preprod.ott.kaltura.com/v4_2/api_v3/service/multirequest")!
                let expectedBodyData = "{\"1\":{\"service\":\"ottUser\",\"action\":\"anonymousLogin\",\"partnerId\":198},\"2\":{\"service\":\"asset\",\"assetType\":\"media\",\"action\":\"getPlaybackContext\",\"assetId\":\"485293\",\"ks\":\"{1:result:ks}\",\"contextDataParams\":{\"context\":\"PLAYBACK\",\"mediaProtocols\":[\"https\"]}},\"clientTag\":\"java:16-09-10\",\"apiVersion\":\"3.6.1078.11798\"}".data(using: .utf8)
                let expectedRequestMethod: RequestMethod = .post
                let expectedHeaders = ["Content-Type": "application/json", "Accept": "application/json"]
                
                waitUntil(timeout: 10) { (done) in
                    let mockExecutor = RequestExecutorMock { (request) in
                        expect(expectedUrl).to(equal(request.url))
                        expect(expectedRequestMethod).to(equal(request.method))
                        expect(expectedBodyData).to(equal(request.dataBody))
                        expect(expectedHeaders).to(equal(request.headers))
                        done()
                    }
                    
                    let provider = PhoenixMediaProvider()
                        .set(sessionProvider: self)
                        .set(assetId: self.mediaID)
                        .set(type: .media)
                        .set(playbackContextType: .playback)
                        .set(executor: mockExecutor)
                    
                    provider.loadMedia { (media, error) in }
                }
            }
        }
    }
}


