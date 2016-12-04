//
//  OTTMediaProviderTest.swift
//  PlayKit
//
//  Created by Rivka Peleg on 04/12/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import XCTest
import PlayKit



class OTTMediaProviderTest: XCTestCase, SessionProvider {

    
    let mediaID = ""
    var partnerId: Int64 = 0
    var serverURL: String  = ""
    func loadKS(completion: (_ result :Result<String>) -> Void){
        completion(Result(data: "123", error: nil))
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
        
        let provider = OTTEntryProvider(sessionProvider: self, mediaId: mediaID, type: AssetType.media, formats: ["HD"], executor: MediaEntryProviderMockExecutor(entryID: mediaID, domain: "ott"))
        provider.loadMedia { (r:Result<MediaEntry>) in
            print(r)
        }
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}


