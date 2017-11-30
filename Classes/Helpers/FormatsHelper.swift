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

public class FormatsHelper {

   static public let supportedFormats: [PKMediaSource.MediaFormat] = [.hls, .mp4, .wvm, .mp3]
    
   static public let supportedSchemes: [DRMParams.Scheme] = [.fairplay, .widevineClassic]

   static public func getMediaFormat(format: String, hasDrm: Bool) -> PKMediaSource.MediaFormat {

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
