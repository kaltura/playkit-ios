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

class TracksTest: XCTestCase {
    var player : Player!
    var tracks: PKTracks?
    
    override func setUp() {
        super.setUp()
        
        let url = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8")
        
        let mediaEntry = PKMediaEntry("test-id",
                                      sources: [PKMediaSource("test", contentUrl: url)],
                                      duration: -1)
        
        self.player = PlayKitManager.shared.loadPlayer(pluginConfig: nil)
        self.player.prepare(MediaConfig(mediaEntry: mediaEntry))
    }
    
    func testGetTracksByEvent() {
        self.player.play()
        
        let theExeption = expectation(description: "get tracks")
        
        self.player.addObserver(self,
                                events: [PlayerEvent.tracksAvailable]) { event in
            
            if event is PlayerEvent.TracksAvailable {
                self.tracks = event.tracks
                
                theExeption.fulfill()
            } else {
                XCTFail()
            }
        }
        
        waitForExpectations(timeout: 10.0) { (_) -> Void in}
    }
    
    func testSelectTrack() {
        self.player.play()
        
        let theExeption = expectation(description: "select track")
        
        self.player.addObserver(self,
                                events: [PlayerEvent.tracksAvailable]) { event in
            if event is PlayerEvent.TracksAvailable {
                print(event)
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
        self.destroyPlayer(player)
    }
}
