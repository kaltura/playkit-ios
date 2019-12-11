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

@objc enum PKAssetStatus: Int, CustomStringConvertible {
    case new
    case preparing
    case prepared
    case faild
    
    var description: String {
        switch self {
        case .new: return "new"
        case .preparing: return "preparing"
        case .prepared: return "prepared"
        case .faild: return "faild"
        }
    }
}

class PKAsset: NSObject {
    let avAsset: AVURLAsset
    let playerSettings: PKPlayerSettings
    let autoBuffer: Bool
    @objc dynamic var status: PKAssetStatus = .new
    
    init(avAsset: AVURLAsset, playerSettings: PKPlayerSettings, autoBuffer: Bool) {
        self.avAsset = avAsset
        self.playerSettings = playerSettings.createCopy()
        self.autoBuffer = autoBuffer
        
        super.init()
    }
}
