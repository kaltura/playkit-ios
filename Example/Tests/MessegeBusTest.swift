//
//  MessegeBusTest.swift
//  PlayKit
//
//  Created by Eliza Sapir on 02/12/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import XCTest
import PlayKit
import SwiftyJSON
import AVFoundation

class MessegeBusTest: XCTestCase {
    var player : Player!
    
    override func setUp() {
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
        
        config.set(mediaEntry: MediaEntry(json: JSON(entry)))
        
        self.player = PlayKitManager.sharedInstance.loadPlayer(config:config)
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPlayerMetadataLoaded() {
        let theExeption = expectation(description: "test play")
        
        self.player.addObserver(self, events: [PlayerEvents.loadedMetadata.self]) { (info: Any) in
            if info as! PKEvent is PlayerEvents.loadedMetadata {
                theExeption.fulfill()
            } else {
                XCTFail()
            }
        }
        
        self.player.play()
        
        waitForExpectations(timeout: 10.0) { (_) -> Void in}
    }
    
    func testPlayerPlayEventsFlow() {
        let theExeption = expectation(description: "test play")
        var isPlay: Bool = false
        
        self.player.addObserver(self, events: [PlayerEvents.play.self, PlayerEvents.playing.self]) { (info: Any) in
            if info as! PKEvent is PlayerEvents.play {
                isPlay = true
            } else if info as! PKEvent is PlayerEvents.playing {
                if isPlay {
                    theExeption.fulfill()
                } else {
                    XCTFail()
                }
                
            } else {
               XCTFail()
            }
        }

        self.player.play()
        
        waitForExpectations(timeout: 10.0) { (_) -> Void in}
    }
    
    func testPlayerPauseEventsFlow() {
        let theExeption = expectation(description: "test play")
        
        self.player.addObserver(self, events: [PlayerEvents.playing.self, PlayerEvents.pause.self]) { (info: Any) in
            if info as! PKEvent is PlayerEvents.playing {
                self.player.pause()
            } else if info as! PKEvent is PlayerEvents.pause {
                theExeption.fulfill()
            } else {
                XCTFail()
            }
        }
        
        self.player.play()
        
        waitForExpectations(timeout: 10.0) { (_) -> Void in}
    }
    
    func testPlayerSeekEventsFlow() {
        let theExeption = expectation(description: "test play")
        
        self.player.addObserver(self, events: [PlayerEvents.playing.self, PlayerEvents.seeking.self, PlayerEvents.seeked.self]) { (info: Any) in
            if info as! PKEvent is PlayerEvents.playing {
                self.player.seek(to: CMTimeMakeWithSeconds(3, 1000000))
            } else if info as! PKEvent is PlayerEvents.seeking {
                theExeption.fulfill()
            } else {
                XCTFail()
            }
        }
        
        self.player.play()
        
        waitForExpectations(timeout: 10.0) { (_) -> Void in}
    }
}
