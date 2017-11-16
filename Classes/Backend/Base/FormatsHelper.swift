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

class FormatsHelper {

   static let supportedFormats: [PKMediaSource.MediaFormat] = [.hls, .mp4, .wvm, .mp3]
    
   static let supportedSchemes: [DRMParams.Scheme] = [.fairplay, .widevineClassic]

   static func getMediaFormat(format: String, hasDrm: Bool) -> PKMediaSource.MediaFormat {

            switch format {
            case "applehttp":
                return .hls
            case "url":
                if hasDrm {
                    return .wvm
                } else {
                    return .mp4
                }
            default:
                return .unknown
            }
    }

}
