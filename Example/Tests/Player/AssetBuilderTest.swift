//
//  AssetBuilderTest.swift
//  PlayKit
//
//  Created by Gal Orlanczyk on 12/06/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import XCTest
@testable import PlayKit
import Quick
import Nimble

class AssetBuilderTest: QuickSpec {
    
    let mp4 = MediaSource("mp4", contentUrl: URL(string: "https://example.com/a.mp4"), mediaFormat: .mp4)
    let hls = MediaSource("hls", contentUrl: URL(string: "https://example.com/hls.m3u8"), mediaFormat: .hls)
    let fps = MediaSource("fps", contentUrl: URL(string: "https://example.com/fps.m3u8"), mediaFormat: .hls)
    let wvm = MediaSource("wvm", contentUrl: URL(string: "https://example.com/a.wvm"), mediaFormat: .wvm )
    
    
    
    override func spec() {
        describe("AssetBuilderTest") {
            let allMediaSources = [mp4, hls, fps, wvm]
            
            it("can select source") {
                guard let (mediaSource, _) = AssetBuilder.getPreferredMediaSource(from: MediaEntry("e", sources: allMediaSources)) else {
                    XCTFail()
                    return
                }
                expect(mediaSource.contentUrl!.lastPathComponent).to(equal("hls.m3u8"))
            }
            
            it("can build asset") {
                guard let (mediaSource, handlerType) = AssetBuilder.getPreferredMediaSource(from: MediaEntry("e", sources: allMediaSources)) else {
                    XCTFail()
                    return
                }
                let _ = AssetBuilder.build(from: mediaSource, using: handlerType) { error, asset in
                    guard let assetUrl = asset?.url else {
                        XCTFail()
                        return
                    }
                    expect(assetUrl).to(equal(mediaSource.contentUrl!))
                }
            }
            
            it("fails when no content url is provided") {
                let mock = MediaSource("mock", contentUrl: URL(string: ""))
            }
        }
    }
}
