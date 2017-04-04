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



class PhoenixMediaProviderTest: XCTestCase, SessionProvider {
    


    
    let mediaID = "485293"
    var partnerId: Int64 = 198
    var serverURL: String  = "http://api-preprod.ott.kaltura.com/v4_2/api_v3"
    
    
    public func loadKS(completion: @escaping (String?, Error?) -> Void) {
        completion(nil, nil)
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
        .set(playbackContextType: PlaybackContextType.playback)
        
        
        provider.loadMedia { (entry, error) in
            print(entry ?? "")
            theExeption.fulfill()
        }
        
        self.waitForExpectations(timeout: 6.0) { (_) -> Void in
            
        }
    }
}


