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

internal enum TrackType {
    case audio
    case text
}

@objc public class Track: NSObject {
    @objc public var id: String
    @objc public var title: String
    @objc public var language: String?
    
    var type: TrackType
    
    init(id: String, title: String, type: TrackType, language: String?) {
        PKLog.verbose("init:: id:\(String(describing: id)) title:\(String(describing: title)) language: \(String(describing: language))")
        
        self.id = id
        self.title = title
        self.type = type
        self.language = language
    }
}
