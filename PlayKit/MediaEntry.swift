//
//  MediaEntry.swift
//  PlayKit
//
//  Created by Noam Tamim on 08/10/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

import UIKit

public class MediaEntry: NSObject {
    let id: String
    var sources: [MediaSource]?
    var duration: Int64?
    
    init(_ id: String) {
        self.id = id
    }
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
}

public class FairPlayDRMData: DRMData {
    var fpsCertificate: Data?    
}
