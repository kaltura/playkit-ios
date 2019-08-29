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
    
    init(id: String, name: String, isDefault: Bool, forced: Bool, language: String, vttURLString: String, duration: Double) {
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
