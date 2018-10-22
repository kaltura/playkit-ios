// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import Foundation

@objc public class PKTracks: NSObject {
    @objc public var audioTracks: [Track]?
    @objc public var textTracks: [Track]?
    
    init(audioTracks: [Track]?, textTracks: [Track]?) {
        PKLog.verbose("init::")
        self.audioTracks = audioTracks
        self.textTracks = textTracks
    }
}

