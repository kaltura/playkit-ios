//
//  OVPMediaProviederTest.swift
//  PlayKit
//
//  Created by Rivka Peleg on 29/11/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import XCTest
import PlayKit




class OVPMediaProviederTest: XCTestCase, SessionProvider {
    
    public func loadKS(completion: @escaping (Result<String>) -> Void) {
         completion(Result(data: "djJ8MjIyMjQwMXwdcXO1uXvBNZYxpUCxIGfEN120AWUJGJYCTt2qbhE3hCXa62-TGAOrxUtA0WwBGCqRreBaAzd2Dnejy9bYmcqtC1SxtCkZjw_jwoFd4Y3Cl-9hYgSCTcLRdqiePConBm8=", error: nil))
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
    
    func testRegularCaseTest() {
        let theExeption = expectation(description: "test")
        
        let provider = OVPMediaProvider()
        .set(sessionProvider: self)
        .set(entryId: self.entryID)
        .set(executor: MediaEntryProviderMockExecutor(entryID: entryID, domain: "ovp"))
        
        provider.loadMedia { (r:Result<MediaEntry>) in
            if (r.error != nil){
                XCTFail()
            }else{
                theExeption.fulfill()
            }
            print(r)
        }
        
        
        self.waitForExpectations(timeout: 6.0) { (_) -> Void in
            
        }
    }
    
    
    func test_new_ovp_api() {
        let theExeption = expectation(description: "test")
        
        let provider = OVPMediaProvider()
            .set(sessionProvider: self)
            .set(entryId: self.entryID)
            .set(executor: USRExecutor.shared )
        
        
        provider.loadMedia { (r:Result<MediaEntry>) in
            if (r.error != nil){
                XCTFail()
            }else{
                theExeption.fulfill()
            }
            print(r)
        }
        
        
        self.waitForExpectations(timeout: 6.0) { (_) -> Void in
            
        }
    }
}


