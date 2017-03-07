//
//  PhoenixAPIDefines.swift
//  Pods
//
//  Created by Rivka Peleg on 02/03/2017.
//
//

import Foundation




public enum AssetType: String {
    case media = "media"
    case epg = "epg"
}

public enum PlaybackContextType: String {
    
    case trailer = "TRAILER"
    case catchup = "CATCHUP"
    case startOver = "START_OVER"
    case playback = "PLAYBACK"
}
