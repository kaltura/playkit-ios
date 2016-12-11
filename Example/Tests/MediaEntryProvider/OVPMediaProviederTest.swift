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
         completion(Result(data: "djJ8MjIwOTU5MXyDmkKuVhHfzNvca2oQWbhyKBVWMCvAGLcEH2QBS1VBmpqoszqPLwCFwl_V-Qdc2-nt9M21RaJIoea-VP0wpcxOHIHlzXADcdKUZ4rovtCRx-U5bnFIwSx17UUfBB80vzM=", error: nil))
    }

    let entryID = "1_1h1vsv3z"
    var partnerId: Int64 = 2209591
    var serverURL: String  = "http://cdnapi.kaltura.com"
    

    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testRegularCaseTest() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let theExeption = expectation(description: "test")
        
        let provider = OVPMediaProvider()
        .set(sessionProvider: self)
        .set(entryId: self.entryID)
        .set(executor: MediaEntryProviderMockExecutor(entryID: entryID, domain: "ovp"))
        .set(apiServerURL: self.serverURL)
        
        
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
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}


