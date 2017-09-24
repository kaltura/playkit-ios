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
import AVFoundation

struct PKAsset {
    let avAsset: AVURLAsset
    let playerSettings: PKPlayerSettings
    
    init(avAsset: AVURLAsset, playerSettings: PKPlayerSettings) {
        self.avAsset = avAsset
        self.playerSettings = playerSettings.createCopy()
    }
}
