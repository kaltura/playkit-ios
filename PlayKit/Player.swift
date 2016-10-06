//
//  Player.swift
//  PlayKit
//
//  Created by Noam Tamim on 28/08/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

import UIKit

func TODO() -> Never {
    fatalError("Not implemented yet")
}

public class Player {
    public init() {
        TODO()
    }

    public func apply(all: PlayerConfig) -> Bool {
        TODO()
    }
    
    public func apply(diff: PlayerConfig) -> Bool {
        TODO()
    }
    
    public lazy var view: PlayerView = {
        return PlayerView(self); 
    }()
    
    public var position: Int64
    public var shouldPlay: Bool
    public func release() {
        TODO()
    }
}


public class PlayerView: UIView {
    init(_ player: Player) {
        TODO()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        TODO()
    }
}

public class PlayerConfig {
    public var mediaEntry : MediaEntry?
    public var position : Int64 = 0
    public var subtitleLanguage : String?
    public var audioLanguage : String?
    public init() {
        TODO()
    }
}


// Model

public class MediaEntry {
}

public class MediaSource {
    let id: String
    var contentUrl: URL?
    var mimeType: String?
    var drmData: DRMData?
    
    init(id: String) {
        self.id = id
    }
}

open class DRMData {
    var licenseURL: URL?
    
    let TBD = TODO()
}

public class FairPlayDRMData: DRMData {
    var fpsCertificate: Data?    
}

class Metadata {
    let TBD = TODO()
}

class CuePoints {
    let TBD = TODO()
}

class PluginData {
    let TBD = TODO()
}

// Providers

public class KalturaMediaEntryProvider {
    
    public var ks: String?
    public let server: String
    public let partnerId: String
    
    public init(server: String, partnerId: String) {
        self.server = server
        self.partnerId = partnerId
    }
    
    public func mediaEntry(_ entryId: String) -> MediaEntry? {
        // Connect to API, retrieve entry metadata and sources
        TODO()
    }
}

