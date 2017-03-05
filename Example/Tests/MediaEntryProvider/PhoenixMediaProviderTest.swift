//
//  PhoenixMediaProviderTest.swift
//  PlayKit
//
//  Created by Rivka Peleg on 04/12/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import XCTest
import PlayKit



class PhoenixMediaProviderTest: XCTestCase, SessionProvider {
    


    
    let mediaID = "258656"
    var partnerId: Int64 = 198
    var serverURL: String  = "http://52.210.223.65:8080/v4_0/api_v3"
    
    
    public func loadKS(completion: @escaping (String?, Error?) -> Void) {
        completion("djJ8MTk4fLsl2jWZfTLBHh80n32POkgauZLWcLXhEEySDRL9yRtOLtr92sPWaKpnCaz4nJgsjjXIxD6PkOLXlOvpEHV3Wizc384sF3F4Kj1MfiqJRQd8", nil)
    }
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testRegularCaseTest() {
        
        let theExeption = expectation(description: "test")
        
        let provider = PhoenixMediaProvider()
        .set(sessionProvider: self)
        .set(assetId: mediaID)
        .set(type: AssetType.media)
        .set(formats: ["Mobile_Devices_Main_HD"])
        
        provider.loadMedia { (entry, error) in
            print(entry ?? "")
            theExeption.fulfill()
        }
        
        self.waitForExpectations(timeout: 6.0) { (_) -> Void in
            
        }
    }
}


