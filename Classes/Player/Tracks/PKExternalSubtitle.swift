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
    @objc public let autoSelect: Bool
    @objc public let forced: Bool
    @objc public let language: String
    @objc public let characteristics: String
    @objc public let vttURLString: String
    @objc public let duration: Double
    
    /**
     Initializes a new PKExternalSubtitle which enables the configuration of external subtitles.
    
     - Parameters:
        - id:               The value is used in order to identify the specific subtitle from the others.
     
        - name:             The value is a quoted-string containing a human-readable description of the Rendition.
     
        - isDefault:        If the value is true, then the client SHOULD play this Rendition of the content in the absence of information from the user indicating a different choice. This attribute is OPTIONAL. It's absence indicates an implicit value of false.
     
        - autoSelect:       If the value is true, then the client MAY choose to play this Rendition in the absence of explicit user preference because it matches the current playback environment, such as chosen system language. This attribute is OPTIONAL.  Its absence indicates an implicit value of false.
     
        - forced:           A value of true indicates that the Rendition contains content that is considered essential to play. When selecting a FORCED Rendition, a client SHOULD choose the one that best matches the current playback environment (e.g., language). This attribute is OPTIONAL. It's absence indicates an implicit value of false.
     
        - language:         The value is a one of the standard Tags for Identifying Languages [RFC5646], which identifies the primary language used in the Rendition. This attribute is OPTIONAL.
     
        - characteristics:  The value contains one or more Uniform Type Identifiers [UTI] separated by comma (,) characters. This attribute is OPTIONAL. Each UTI indicates an individual characteristic of the Rendition.
     
        - vttURLString:     This is the string URL of the vtt.
     
        - duration:         This is the media's duration.
     */
    @objc public init(id: String, name: String, isDefault: Bool = false, autoSelect: Bool = false, forced: Bool = false, language: String? = "", characteristics: String? = "", vttURLString: String, duration: Double) {
        self.id = id
        self.name = name
        self.isDefault = isDefault
        self.autoSelect = autoSelect
        self.forced = forced
        self.language = language ?? ""
        self.characteristics = characteristics ?? ""
        self.vttURLString = vttURLString
        self.duration = duration
    }
    
    public override var description: String {
        return super.description + """
        id: \(id)
        name: \(name)
        isDefault: \(isDefault)
        autoSelect: \(autoSelect)
        forced: \(forced)
        language: \(language)
        characteristics: \(characteristics)
        vttURLString: \(vttURLString)
        duration: \(duration)
        """
    }
}
