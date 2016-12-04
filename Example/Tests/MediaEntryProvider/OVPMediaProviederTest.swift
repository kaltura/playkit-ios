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

    let entryID = "1_1h1vsv3z"
    var partnerId: Int64 = 2209591
    var serverURL: String  = "http://cdnapi.kaltura.com"
    
    func loadKS(completion: (_ result :Result<String>) -> Void){
        
        completion(Result(data: "djJ8MjIwOTU5MXyDmkKuVhHfzNvca2oQWbhyKBVWMCvAGLcEH2QBS1VBmpqoszqPLwCFwl_V-Qdc2-nt9M21RaJIoea-VP0wpcxOHIHlzXADcdKUZ4rovtCRx-U5bnFIwSx17UUfBB80vzM=", error: nil))
    }

    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func regularCaseTest() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let provider = OVPMediaProvider(sessionProvider: self, entryId: entryID, uiconfId:nil , executor: MediaEntryProviderMockExecutor(entryID: entryID, domain: "ovp"))
        provider.loadMedia { (r:Result<MediaEntry>) in
            print(r)
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}


