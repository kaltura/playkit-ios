//
//  SourceSelectorTest.swift
//  PlayKit
//
//  Created by Noam Tamim on 12/01/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import XCTest
import AVFoundation
@testable import PlayKit

class SourceSelectorTest: XCTestCase {
    
    let mp4 = MediaSource("mp4", contentUrl: URL(string: "https://example.com/a.mp4"), mediaFormat: .mp4)
    let hls = MediaSource("hls", contentUrl: URL(string: "https://example.com/hls.m3u8"), mediaFormat: .hls)
    let fps = MediaSource("fps", contentUrl: URL(string: "https://example.com/fps.m3u8"), mediaFormat: .hls)
    let wvm = MediaSource("wvm", contentUrl: URL(string: "https://example.com/a.wvm"), mediaFormat: .wvm )
    
    func testSelectedSource() {
        guard let preferredMedia = AssetBuilder.getPreferredMediaSource(from: MediaEntry("e", sources: [mp4, hls, fps])) else {
            XCTFail()
            return
        }
        AssetBuilder.build(from: preferredMedia.0, using: preferredMedia.1) { (_, asset) in
            guard let asset = asset else {
                XCTFail()
                return
            }
            XCTAssertEqual(asset.url.lastPathComponent, "hls.m3u8")
        }
    }
    
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
