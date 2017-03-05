//
//  OTTSessionProviderTest.swift
//  PlayKit
//
//  Created by Rivka Peleg on 04/12/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import XCTest
import PlayKit

class OTTSessionProviderTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testOTTSessionProvider() {
        
        let sessionProvider = OTTSessionManager(serverURL:"http://52.210.223.65:8080/v4_0/api_v3", partnerId:198, executor: nil)
        sessionProvider.startAnonymousSession { (e:Error?) in
            if e == nil{
                sessionProvider.loadKS(completion: { (ks, error) in
                        print(ks ?? "")
                })
            }else{
                
            }
            
        }
    }
}
