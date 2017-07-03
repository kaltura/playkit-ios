// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license,
// unless a different license for a particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import Foundation

@objc public class Track: NSObject {
    @objc public var id: String
    @objc public var title: String
    @objc public var language: String?
    
    init(id: String, title: String, language: String?) {
        PKLog.debug("init:: id:\(String(describing: id)) title:\(String(describing: title)) language: \(String(describing: language))")
        
        self.id = id
        self.title = title
        self.language = language
    }
}
