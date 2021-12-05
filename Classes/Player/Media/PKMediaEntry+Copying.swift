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

extension PKMediaEntry: NSCopying {
    
    public func copy(with zone: NSZone? = nil) -> Any {
        
        let sources = self.sources?.compactMap{ $0.copy() as? PKMediaSource }
        
        let entry = PKMediaEntry(self.id,
                                 sources: sources,
                                 duration: self.duration)
        entry.mediaType = self.mediaType
        entry.metadata = self.metadata
        entry.name = self.name
        entry.externalSubtitles = self.externalSubtitles
        entry.thumbnailUrl = self.thumbnailUrl
        entry.tags = self.tags
        
        return entry
    }
}

extension PKMediaSource: NSCopying {
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let source = PKMediaSource(self.id,
                                   contentUrl: self.contentUrl,
                                   mimeType: self.mimeType,
                                   drmData: self.drmData,
                                   mediaFormat: self.mediaFormat)
        
        source.externalSubtitle = self.externalSubtitle
        source.contentRequestAdapter = self.contentRequestAdapter
        
        return source
    }
}
