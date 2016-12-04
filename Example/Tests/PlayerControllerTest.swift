//
//  PlayerControllerTest.swift
//  PlayKit
//
//  Created by Itay Kinnrot on 04/12/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import XCTest
import PlayKit
import SwiftyJSON

//Unit test to check the player controller
//If somthing is break here we should raise a red flag - since this is our public API
class PlayerControllerTest: XCTestCase {
    var player : Player!

    
    override func setUp() {
        super.setUp()
        super.setUp()
        
        let config = PlayerConfig()
        
        var source = [String : Any]()
        source["id"] = "test"
        source["url"] = "https://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4"
        
        var sources = [JSON]()
        sources.append(JSON(source))
        
        var entry = [String : Any]()
        entry["id"] = "test"
        entry["sources"] = sources
        
        if let media = MediaEntry(json: JSON(entry)) {
         
            config.set(mediaEntry: media)
            self.player = PlayKitManager.sharedInstance.loadPlayer(config:config)
        
        }
}

        
        
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPlayCommand() {
        let theExeption = expectation(description: "play command")
        self.player.play();
        self.player.addObserver(self, events: [PlayerEvents.playing.self]) { (info: Any) in
            if info as! PKEvent is PlayerEvents.playing {
                theExeption.fulfill()
            } else {
                XCTFail()
            }
        
        
        }
         waitForExpectations(timeout: 10.0) { (_) -> Void in}
    }
    
    func testPauseCommand() {
        let theExeption = expectation(description: "pause command")
        self.player.play();
        self.player.addObserver(self, events: [PlayerEvents.pause.self]) { (info: Any) in
            if info as! PKEvent is PlayerEvents.pause {
                theExeption.fulfill()
            } else {
                XCTFail()
            }
            
            
        }
        self.player.pause()
        waitForExpectations(timeout: 10.0) { (_) -> Void in}
    }
    


    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
