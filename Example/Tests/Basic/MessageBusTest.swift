// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license,
// unless a different license for a particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import XCTest
import PlayKit
import SwiftyJSON
import AVFoundation

class MessageBusTest: XCTestCase {
    var player : Player!
    
    override func setUp() {
        super.setUp()
        self.player = self.createPlayer()
    }
    
    override func tearDown() {
        super.tearDown()
        self.destroyPlayer(player)
    }
    
    func testPlayerMetadataLoaded() {
        let asyncExpectation = expectation(description: "test loadedMetadata event")
        
        self.player.addObserver(self, events: [PlayerEvent.loadedMetadata]) { event in
            if type(of: event) == PlayerEvent.loadedMetadata {
                asyncExpectation.fulfill()
            } else {
                XCTFail()
            }
        }
        
        self.player.play()
        
        waitForExpectations(timeout: 10.0) { (_) -> Void in}
    }
    
    func testPlayerPlayEventsFlow() {
        let asyncExpectation = expectation(description: "test play and playing + make sure playing is after play")
        var isPlay: Bool = false
        
        self.player.addObserver(self, events: [PlayerEvent.play, PlayerEvent.playing]) { event in
            if type(of: event) == PlayerEvent.play {
                isPlay = true
            } else if type(of: event) == PlayerEvent.playing {
                if isPlay {
                    asyncExpectation.fulfill()
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
        let theExeption = expectation(description: "test pause")
        
        self.player.addObserver(self, events: [PlayerEvent.playing, PlayerEvent.pause]) { event in
            if type(of: event) == PlayerEvent.playing {
                self.player.pause()
            } else if type(of: event) == PlayerEvent.pause {
                theExeption.fulfill()
            } else {
                XCTFail()
            }
        }
        
        self.player.play()
        
        waitForExpectations(timeout: 10.0) { (_) -> Void in}
    }
    
    func testPlayerSeekEventsFlow() {
        let asyncExpectation = expectation(description: "test seek")
        let seekTime:TimeInterval = 3.0
        var isSeeking = false
        self.player.addObserver(self, events: [PlayerEvent.playing, PlayerEvent.seeking, PlayerEvent.seeked]) { event in
            if type(of: event) == PlayerEvent.playing {
                self.player.seek(to: 3)
            } else if type(of: event) == PlayerEvent.seeking {
                print(self.player.currentTime as Any)
                if (self.player.currentTime == seekTime){
                    isSeeking = true
                } else {
                    XCTFail("seeking issue")
                }
            } else if type(of: event) == PlayerEvent.seeked {
                if isSeeking {
                    asyncExpectation.fulfill()
                } else {
                    XCTFail("seeking issue")
                }
            } else {
                XCTFail()
            }
        }
        
        self.player.play()
        
        waitForExpectations(timeout: 10.0) { (_) -> Void in}
    }
}
