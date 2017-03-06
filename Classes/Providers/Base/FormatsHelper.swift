//
//  FormatsHelper.swift
//  Pods
//
//  Created by Rivka Peleg on 05/03/2017.
//
//

import Foundation

public class FormatsHelper {

   static let supportedFormats: [MediaSource.MediaFormat] = [.hls,.mp4,.wvm,.mp3]
   static let supportedSchemes: [DRMParams.Scheme] = [.fairplay,.widevineClassic]
    
    static func getMediaFormat (format: String, hasDrm:Bool ) -> MediaSource.MediaFormat {
        
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
