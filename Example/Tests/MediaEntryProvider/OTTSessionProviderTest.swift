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
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
            }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testOTTSessionProvider() {
        
        let sessionProvider = OTTSessionManager(serverURL:"http://52.210.223.65:8080/v4_0/api_v3", partnerId:198, executor: nil)
        sessionProvider.startAnonymouseSession { (e:Error?) in
            if e == nil{
                sessionProvider.loadKS(completion: { (r:Result<String>) in
                    print(r.data)
                    
                })
            }else{
                
            }
            
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
