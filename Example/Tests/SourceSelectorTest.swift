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
import AVFoundation
@testable import PlayKit

class SourceSelectorTest: XCTestCase {
    
    let mp4 = PKMediaSource("mp4", contentUrl: URL(string: "https://example.com/a.mp4"), mediaFormat: .mp4)
    let hls = PKMediaSource("hls", contentUrl: URL(string: "https://example.com/hls.m3u8"), mediaFormat: .hls)
    let fps = PKMediaSource("fps", contentUrl: URL(string: "https://example.com/fps.m3u8"), mediaFormat: .hls)
    let wvm = PKMediaSource("wvm", contentUrl: URL(string: "https://example.com/a.wvm"), mediaFormat: .wvm )
    
    func testSelectedSource() {
        guard let preferredMedia = AssetBuilder.getPreferredMediaSource(from: PKMediaEntry("e", sources: [mp4, hls, fps])) else {
            XCTFail()
            return
        }
        let _ = AssetBuilder.build(from: preferredMedia.0, using: preferredMedia.1) { (_, asset) in
            guard let asset = asset else {
                XCTFail()
                return
            }
            XCTAssertEqual(asset.url.lastPathComponent, "hls.m3u8")
        }
    }
}
