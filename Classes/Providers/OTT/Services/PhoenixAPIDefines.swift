//
//  PhoenixAPIDefines.swift
//  Pods
//
//  Created by Rivka Peleg on 02/03/2017.
//
//

import Foundation


public enum AssetType: String {
    case vod = "vod"
    case channel = "channel"
    case recording = "recording"
    case shifted = "shifted"
    
    func objectType() -> String {
        switch self {
        case .vod, .channel:
            return "media"
        case .shifted, .recording :
            return "epg"
        default:
            return "media"
        }
    }
    
    func mediaType() -> MediaType {
        switch self {
        case .vod, .recording:
            return MediaType.vod
        case .channel, .shifted:
               return MediaType.live
        default:
            return MediaType.unknown
        }
    }
}

public enum PlaybackContextType: String {
    
    case trailer = "TRAILER"
    case catchup = "CATCHUP"
    case startOver = "START_OVER"
    case playback = "PLAYBACK"
}
