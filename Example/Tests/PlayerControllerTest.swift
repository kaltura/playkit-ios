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
import CoreMedia

//Unit test to check the player controller
//If somthing is break here we should raise a red flag - since this is our public API
class PlayerControllerTest: XCTestCase {
    
    var player : Player!
    
    override func setUp() {
        super.setUp()
        
        var source = [String : Any]()
        source["id"] = "test"
        source["url"] = "https://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4"
        
        var sources = [JSON]()
        sources.append(JSON(source))
        
        var entry = [String : Any]()
        entry["id"] = "test"
        entry["sources"] = sources
        let mediaConfig = MediaConfig(mediaEntry: MediaEntry(json: entry))
        
        do{
        self.player = try PlayKitManager.shared.loadPlayer(pluginConfig: nil)
        } catch {
            
        }
        self.player.prepare(mediaConfig)
    }
    
    override func tearDown() {
        super.tearDown()
        self.player.destroy()
    }
    
    func testPlayCommand() {
        let asyncExpectation = expectation(description: "play command")
        self.player.play();
        self.player.addObserver(self, events: [PlayerEvent.playing]) { event in
            if type(of: event) == PlayerEvent.playing {
                asyncExpectation.fulfill()
            } else {
                XCTFail()
            }
        }
        waitForExpectations(timeout: 10.0) { (_) -> Void in}
    }
    
    func testPauseCommand() {
        let asyncExpectation = expectation(description: "pause command")
        self.player.play();
        self.player.addObserver(self, events: [PlayerEvent.pause]) { event in
            if type(of: event) == PlayerEvent.pause {
                asyncExpectation.fulfill()
            } else {
                XCTFail()
            }
        }
        self.player.pause()
        waitForExpectations(timeout: 10.0) { (_) -> Void in}
    }
    
    
    func testIsPlayingValue() {
        let asyncExpectation = expectation(description: "play command")
        self.player.play();
        self.player.addObserver(self, events: [PlayerEvent.playing, PlayerEvent.pause]) { event in
            
            if type(of: event) == PlayerEvent.playing {
                if self.player.isPlaying {
                    self.player.pause()
                } else {
                    XCTFail()
                }
            } else if type(of: event) == PlayerEvent.pause {
                if !self.player.isPlaying {
                    asyncExpectation.fulfill()
                } else {
                    XCTFail()
                }
            }
        }
        waitForExpectations(timeout: 10.0) { (_) -> Void in}
    }
    
    /// Test a guard mechanism that prevents receiving pause events after ended event.
    ///
    /// ## The Flow:
    /// 1. play the video.
    /// 2. seek to 2 seconds before the end.
    /// 3. on ended event pause the player.
    ///
    /// **expected result:** shouldn't receive the pause event and expectation should be fullfilled.
    func testEnded() {
        let asyncExpectation = expectation(description: "ended event")
        var isEnded = false
        var isFirstPlay = true
        
        self.player.addObserver(self, events: [PlayerEvent.ended]) { info in
            print("ended")
            isEnded = true
            self.player.pause()
        }
        self.player.addObserver(self, events: [PlayerEvent.playing, PlayerEvent.pause]) { event in
            if type(of: event) == PlayerEvent.playing && isFirstPlay && self.player.isPlaying {
                isFirstPlay = false
                // seek to end - 1 second
                self.player.seek(to: CMTimeMake(Int64(self.player.duration - 2), 1))
            }
            // should not fire play/pause after ended
            if isEnded {
                XCTFail()
            }
        }
        player.play()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 9) {
            asyncExpectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    /// Test to make sure pause/play events are received after ended + seeked event.
    ///
    /// ## The Flow:
    /// 1. play the video.
    /// 2. seek to 2 seconds before the end.
    /// 3. on ended event seek again to 2 seconds before the end.
    /// 4. play again
    /// 
    /// **expected result:** receive play event after ended + seeked
    func testAnalyticsEndedSeekedPlayed() {
        let asyncExpectation = expectation(description: "ended -> seek -> play events")
        var isEnded = false
        var isFirstPlay = true
        var isSeekedAfterEnded = false
        
        player.addObserver(self, events: [PlayerEvent.ended]) { info in
            print("ended")
            isEnded = true
            self.player.seek(to: CMTimeMake(Int64(self.player.duration - 2), 1))
        }
        player.addObserver(self, events: [PlayerEvent.playing, PlayerEvent.pause]) { event in
            if type(of: event) == PlayerEvent.playing && isFirstPlay && self.player.isPlaying {
                isFirstPlay = false
                // seek to end - 2 second
                self.player.seek(to: CMTimeMake(Int64(self.player.duration - 2), 1))
            }
            // should fire play/pause after ended + seeked
            if isSeekedAfterEnded {
                asyncExpectation.fulfill()
            }
        }
        player.addObserver(self, events: [PlayerEvent.seeked]) { info in
            if isEnded {
                isSeekedAfterEnded = true
                self.player.play()
            }
        }
        player.play()
        
        waitForExpectations(timeout: 20, handler: nil)
    }
}
