//
//  OVPMediaProviederTest.swift
//  PlayKit
//
//  Created by Rivka Peleg on 29/11/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import XCTest
import PlayKit
import KalturaNetKit

class OVPMediaProviederTest: XCTestCase, SessionProvider {
    
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
    
    /* test not working
    func testRegularCaseTest() {
        let theExeption = expectation(description: "test")
        
        let provider = OVPMediaProvider()
        .set(sessionProvider: self)
        .set(entryId: self.entryID)
        .set(executor: MediaEntryProviderMockExecutor(entryID: entryID, domain: "ovp"))
        
        provider.loadMedia { (media, error) in
            if (error != nil){
                XCTFail()
            }else{
                theExeption.fulfill()
            }
           
        }
        
        
        self.waitForExpectations(timeout: 6.0) { (_) -> Void in
            
        }
    }*/
    
    func test_new_ovp_api() {
        let theExeption = expectation(description: "test")
        
        let provider = OVPMediaProvider()
            .set(sessionProvider: self)
            .set(entryId: self.entryID)
            .set(executor: USRExecutor.shared )
        
        
        provider.loadMedia { (media, error) in
            if (error != nil){
                XCTFail()
            }else{
                theExeption.fulfill()
            }
        }
        
        
        self.waitForExpectations(timeout: 6.0) { (_) -> Void in
            
        }
    }
}


