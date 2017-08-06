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

/// Media Source Type
enum SourceType {
    case mp3
    case mp4
    case m3u8
    case wvm
    
    var asStr: String {
        switch self {
        case .mp3:
            return "mp3"
        case .mp4:
            return "mp4"
        case .m3u8:
            return "m3u8"
        case .wvm:
            return "wvm"
        }
    }
}

/// Selects the preffered media source
class SourceSelector {
    static func selectSource(from mediaEntry: PKMediaEntry) -> (PKMediaSource, AssetHandler.Type)? {
        guard let sources = mediaEntry.sources else {
            PKLog.error("no media sources in mediaEntry!")
            return nil
        }
        
        let defaultHandler = DefaultAssetHandler.self
        
        // Preference: Local, HLS, FPS*, MP4, WVM*, MP3
        
        if let source = sources.first(where: {$0 is LocalMediaSource}) {
            if source.fileExt == SourceType.wvm.asStr {
                return (source, DRMSupport.widevineClassicHandler!)
            } else {
                return (source, defaultHandler)
            }
        }
        
        if DRMSupport.fairplay {
            if let source = sources.first(where: {$0.fileExt == SourceType.m3u8.asStr}) {
                return (source, defaultHandler)
            }
        } else {
            if let source = sources.first(where: {$0.fileExt == SourceType.m3u8.asStr && ($0.drmData == nil || $0.drmData!.isEmpty) }) {
                return (source, defaultHandler)
            }
        }
        
        if let source = sources.first(where: {$0.fileExt == SourceType.mp4.asStr}) {
            return (source, defaultHandler)
        }
        
        if DRMSupport.widevineClassic, let source = sources.first(where: {$0.fileExt == SourceType.wvm.asStr}) {
            return (source, DRMSupport.widevineClassicHandler!)
        }
        
        if let source = sources.first(where: {$0.fileExt == SourceType.mp3.asStr}) {
            return (source, defaultHandler)
        }
        
        PKLog.error("no playable media sources!")
        
        return nil
    }
}
