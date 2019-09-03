//
//  PKExternalSubtitle.swift
//  PlayKit
//
//  Created by Nilit Danan on 8/29/19.
//

import Foundation

@objc public class PKExternalSubtitle: NSObject {
    @objc public let id: String
    @objc public let name: String
    @objc public let isDefault: Bool
    @objc public let forced: Bool
    @objc public let language: String
    @objc public let vttURLString: String
    @objc public let duration: Double
    
    /**
     Initializes a new PKExternalSubtitle which enables the configuration of external subtitles.
    
     - Parameters:
        - id:              The value is used in order to identify the specific subtitle from the others.
     
        - name:            The value is a quoted-string containing a human-readable description of the Rendition.
     
        - isDefault:       If the value is true, then the client SHOULD play this Rendition of the content in the absence of information from the user indicating a different choice. This attribute is OPTIONAL. It's absence indicates an implicit value of false.
     
        - forced:          A value of true indicates that the Rendition contains content that is considered essential to play. When selecting a FORCED Rendition, a client SHOULD choose the one that best matches the current playback environment (e.g., language). This attribute is OPTIONAL. It's absence indicates an implicit value of false.
     
        - language:        The value is a one of the standard Tags for Identifying Languages [RFC5646], which identifies the primary language used in the Rendition. This attribute is OPTIONAL.
     
        - vttURLString:    This is the string URL of the vtt.
     
        - duration:        This is the media's duration.
     */
    public init(id: String, name: String, isDefault: Bool = false, forced: Bool = false, language: String = "", vttURLString: String, duration: Double) {
        self.id = id
        self.name = name
        self.isDefault = isDefault
        self.forced = forced
        self.language = language
        self.vttURLString = vttURLString
        self.duration = duration
    }
    
    public override var description: String {
        return super.description + """
        id: \(id)
        name: \(name)
        isDefault: \(isDefault)
        forced: \(forced)
        language: \(language)
        vttURLString: \(vttURLString)
        duration: \(duration)
        """
    }
}
