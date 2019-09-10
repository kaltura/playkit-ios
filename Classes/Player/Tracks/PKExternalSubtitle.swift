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
    @objc public let language: String
    @objc public let vttURLString: String
    @objc public let duration: Double
    @objc public let isDefault: Bool
    @objc public let autoSelect: Bool
    @objc public let forced: Bool
    @objc public let characteristics: String
    
    static let groupID = "subs"
    
    /**
     Initializes a new PKExternalSubtitle which enables the configuration of external subtitles.
    
     - Parameters:
        - id:               The value is used in order to identify the specific subtitle from the others.
     
        - name:             The value is a quoted-string containing a human-readable description of the Rendition.
     
        - language:         The value is a one of the standard Tags for Identifying Languages [RFC5646], which identifies the primary language used in the Rendition.
     
        - vttURLString:     This is the string URL of the vtt.
     
        - duration:         This is the media's duration.
     
        - isDefault:        If the value is true, then the client SHOULD play this Rendition of the content in the absence of information from the user indicating a different choice. This attribute is OPTIONAL. It's absence indicates an implicit value of false.
     
        - autoSelect:       If the value is true, then the client MAY choose to play this Rendition in the absence of explicit user preference because it matches the current playback environment, such as chosen system language. This attribute is OPTIONAL.  Its absence indicates an implicit value of false.
     
        - forced:           A value of true indicates that the Rendition contains content that is considered essential to play. When selecting a FORCED Rendition, a client SHOULD choose the one that best matches the current playback environment (e.g., language). This attribute is OPTIONAL. It's absence indicates an implicit value of false.
     
        - characteristics:  The value contains one or more Uniform Type Identifiers [UTI] separated by comma (,) characters. This attribute is OPTIONAL. Each UTI indicates an individual characteristic of the Rendition.
     */
    @objc public init(id: String, name: String, language: String, vttURLString: String, duration: Double, isDefault: Bool = false, autoSelect: Bool = false, forced: Bool = false, characteristics: String? = "") {
        
        self.id = id
        self.name = name
        self.language = language
        self.vttURLString = vttURLString
        self.duration = duration
        self.isDefault = isDefault
        self.autoSelect = autoSelect
        self.forced = forced
        self.characteristics = characteristics ?? ""
    }
    
    public override var description: String {
        return super.description + """
        id: \(id)
        name: \(name)
        language: \(language)
        vttURLString: \(vttURLString)
        duration: \(duration)
        isDefault: \(isDefault)
        autoSelect: \(autoSelect)
        forced: \(forced)
        characteristics: \(characteristics)
        """
    }
    
    func buildM3u8Playlist() -> String {
        let durationString = String(format: "%.3f", duration)
        let intDuration = Int(duration)
        let m3u8Playlist = """
        #EXTM3U
        #EXT-X-VERSION:3
        #EXT-X-MEDIA-SEQUENCE:1
        #EXT-X-PLAYLIST-TYPE:VOD
        #EXT-X-ALLOW-CACHE:NO
        #EXT-X-TARGETDURATION:\(intDuration)
        #EXTINF:\(durationString), no desc
        \(vttURLString)
        #EXT-X-ENDLIST
        """
        return m3u8Playlist
    }
    
    func buildMasterLine() -> String {
        var masterLine = """
        \n#EXT-X-MEDIA:TYPE=SUBTITLES,GROUP-ID="\(PKExternalSubtitle.groupID)",NAME="\(name)",URI="subtitlesm3u8://\(id)"
        """
        
        /*
         The value is an enumerated-string; valid strings are YES and NO.
         If the value is YES, then the client SHOULD play this Rendition of
         the content in the absence of information from the user indicating
         a different choice.  This attribute is OPTIONAL.  Its absence
         indicates an implicit value of NO.
         */
        if isDefault {
            masterLine.append(",DEFAULT=YES")
        }
        
        /*
         The value is an enumerated-string; valid strings are YES and NO.
         This attribute is OPTIONAL.  Its absence indicates an implicit
         value of NO.  If the value is YES, then the client MAY choose to
         play this Rendition in the absence of explicit user preference
         because it matches the current playback environment, such as
         chosen system language.
         
         If the AUTOSELECT attribute is present, its value MUST be YES if
         the value of the DEFAULT attribute is YES.
         */
        if autoSelect {
            masterLine.append(",AUTOSELECT=YES")
        }
        
        /*
         The value is an enumerated-string; valid strings are YES and NO.
         This attribute is OPTIONAL.  Its absence indicates an implicit
         value of NO.  The FORCED attribute MUST NOT be present unless the
         TYPE is SUBTITLES.
         */
        if forced {
            masterLine.append(",FORCED=YES")
        }
        
        /*
         The value is a quoted-string containing one of the standard Tags
         for Identifying Languages [RFC5646], which identifies the primary
         language used in the Rendition.  This attribute is OPTIONAL.
         */
        if !language.isEmpty {
            masterLine.append("""
                ,LANGUAGE="\(language)"
                """)
        }
        
        /*
         The value is a quoted-string containing one or more Uniform Type
         Identifiers [UTI] separated by comma (,) characters.  This
         attribute is OPTIONAL.  Each UTI indicates an individual
         characteristic of the Rendition.
         
         A SUBTITLES Rendition MAY include the following characteristics:
         "public.accessibility.transcribes-spoken-dialog",
         "public.accessibility.describes-music-and-sound", and
         "public.easy-to-read" (which indicates that the subtitles have
         been edited for ease of reading).
         */
        if !characteristics.isEmpty {
            masterLine.append("""
                ,CHARACTERISTICS="\(characteristics)"
                """)
        }
        
        masterLine.append("\n")
        
        return masterLine
    }
}
