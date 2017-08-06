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

class AssetBuilder {
    // builds the asset from the selected media source
    static func build(from mediaSource: PKMediaSource, using assetHandlerType: AssetHandler.Type, readyCallback: @escaping (Error?, AVURLAsset?) -> Void) -> AssetHandler {
        let handler = assetHandlerType.init()
        handler.buildAsset(mediaSource: mediaSource, readyCallback: readyCallback)
        return handler
    }
}

public protocol AssetHandler {
    init()
    func buildAsset(mediaSource: PKMediaSource, readyCallback: @escaping (Error?, AVURLAsset?) -> Void)
}

protocol RefreshableAssetHandler: AssetHandler {
    func shouldRefreshAsset(mediaSource: PKMediaSource, refreshCallback: @escaping (Bool) -> Void)
    func refreshAsset(mediaSource: PKMediaSource)
}

enum AssetError : Error {
    case noFpsCertificate
    case noLicenseUri
    case invalidDrmScheme
    case invalidContentUrl(URL?)
    case noPlayableSources
}

class DRMSupport {
    // FairPlay is not available in simulators and before iOS8
    static let fairplay: Bool = {
        if !Platform.isSimulator, #available(iOS 8, *) {
            return true
        } else {
            return false
        }
    }()
    
    // FairPlay is not available in simulators and is only downloadable in iOS10 and up.
    static let fairplayOffline: Bool = {
        if !Platform.isSimulator, #available(iOS 10, *) {
            return true
        } else {
            return false
        }
    }()
    
    // Widevine is optional (and not available in simulators)
    static let widevineClassic = widevineClassicHandler != nil
    
    // Preload the Widevine Classic Handler, if available
    static let widevineClassicHandler: AssetHandler.Type? = {
        if Platform.isSimulator {
            return nil
        }
        return NSClassFromString("PlayKit.WidevineClassicAssetHandler") as? AssetHandler.Type
    }()
}



