//
//  TracksTest.swift
//  PlayKit
//
//  Created by Eliza Sapir on 11/12/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import XCTest
import PlayKit
import SwiftyJSON

class TracksTest: XCTestCase {
    var player : Player!
    var tracks: PKTracks?
    
    override func setUp() {
        super.setUp()
        
        let config = PlayerConfig()
        
        var source = [String : Any]()
        source["id"] = "test"
        source["url"] = "https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"
        
        var sources = [JSON]()
        sources.append(JSON(source))
        
        var entry = [String : Any]()
        entry["id"] = "test"
        entry["sources"] = sources
        
        config.set(mediaEntry: MediaEntry(json: JSON(entry)))
        
        self.player = PlayKitManager.sharedInstance.loadPlayer(config:config)
    }
    
    func testGetTracksByEvent() {
        let theExeption = expectation(description: "get tracks")
        
        self.player.addObserver(self, events: [PlayerEvents.tracksAvailable.self]) { (data: Any) in
            if let tracksAvailable = data as? PlayerEvents.tracksAvailable {
                self.tracks = tracksAvailable.tracks
                
                theExeption.fulfill()
            } else {
               XCTFail()
            }
        }

        waitForExpectations(timeout: 10.0) { (_) -> Void in}
    }
    
    func testSelectTrack() {
        let theExeption = expectation(description: "select track")
        
        self.player.addObserver(self, events: [PlayerEvents.tracksAvailable.self]) { (data: Any) in
            if let tracksAvailable = data as? PlayerEvents.tracksAvailable {
                print(tracksAvailable)
                self.player.selectTrack(trackId: "sbtl:0")
                
              theExeption.fulfill()
            } else {
                XCTFail()
            }
        }
        
        waitForExpectations(timeout: 10.0) { (_) -> Void in}
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
}
