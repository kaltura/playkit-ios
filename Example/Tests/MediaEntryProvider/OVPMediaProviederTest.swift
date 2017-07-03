// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license,
// unless a different license for a particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import XCTest
@testable import PlayKit
import KalturaNetKit
import Nimble
import Quick

class OVPMediaProviederTest: QuickSpec, SessionProvider {
    
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
    
    public func loadKS(completion: @escaping (String?, Error?) -> Void) {
        completion("", nil)
    }
    
    let entryID = "1_ytsd86sc"
    var partnerId: Int64 = 2222401
    var serverURL: String  = "https://cdnapisec.kaltura.com"
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    /************************************************************/
    // MARK: - Tests
    /************************************************************/
    
    override func spec() {
        describe("OVPMediaProviderTest") {
            it("should make a request") {
                let expectedUrl = URL(string: "https://cdnapisec.kaltura.com/api_v3/service/multirequest")!
                let expectedBodyData = "{\"1\":{\"service\":\"session\",\"action\":\"startWidgetSession\",\"widgetId\":\"_2222401\"},\"2\":{\"responseProfile\":{\"fields\":\"mediaType,dataUrl,id,name,duration,msDuration,flavorParamsIds\",\"type\":1},\"action\":\"list\",\"filter\":{\"redirectFromEntryId\":\"1_ytsd86sc\"},\"service\":\"baseEntry\",\"ks\":\"{1:result:ks}\"},\"3\":{\"entryId\":\"1_ytsd86sc\",\"action\":\"getPlaybackContext\",\"service\":\"baseEntry\",\"contextDataParams\":{\"objectType\":\"KalturaContextDataParams\"},\"ks\":\"{1:result:ks}\"},\"4\":{\"filter:objectType\":\"KalturaMetadataFilter\",\"action\":\"list\",\"filter:metadataObjectTypeEqual\":\"1\",\"service\":\"metadata_metadata\",\"filter:objectIdEqual\":\"1_ytsd86sc\",\"ks\":\"{1:result:ks}\"},\"clientTag\":\"playkit\",\"format\":1,\"apiVersion\":\"3.3.0\"}".data(using: .utf8)
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
                    
                    let provider = OVPMediaProvider()
                        .set(sessionProvider: self)
                        .set(entryId: self.entryID)
                        .set(executor: mockExecutor)
                    
                    provider.loadMedia { (media, error) in }
                }
            }
        }
    }
}


