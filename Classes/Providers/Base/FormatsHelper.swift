//
//  FormatsHelper.swift
//  Pods
//
//  Created by Rivka Peleg on 05/03/2017.
//
//

import Foundation

public class FormatsHelper {
    
    public enum StreamFormat: String {
        
        case mpegDash = "mpegdash"
        case appleHttp = "applehttp"
        case url = "url"
        case unknown = "unknown"
    }
    
    // not sure i need this
    private static let supportedFormats: [MediaSource.SourceType] = [MediaSource.SourceType.hlsClear,MediaSource.SourceType.hlsFairPlay,MediaSource.SourceType.mp4Clear,MediaSource.SourceType.wvmWideVine]
    
    
    static func getSourceType(format: String?, hasDrm: Bool) -> MediaSource.SourceType {
        
        if let format = format {
            switch format {
            case "applehttp":
                if hasDrm {
                    return MediaSource.SourceType.hlsClear
                } else {
                    return MediaSource.SourceType.hlsFairPlay
                }
            case "url":
                if hasDrm {
                    return MediaSource.SourceType.mp4Clear
                } else {
                    return MediaSource.SourceType.wvmWideVine
                }
            default:
                return MediaSource.SourceType.unknown
            }
        }
        
        return MediaSource.SourceType.unknown
    }
}
