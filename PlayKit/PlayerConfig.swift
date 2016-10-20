//
//  PlayerConfig.swift
//  PlayKit
//
//  Created by Noam Tamim on 09/10/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

import Foundation

public class PlayerConfig {
    public init() {}
    public init(mediaEntry: MediaEntry) {
        self.mediaEntry = mediaEntry
    }
    public var mediaEntry : MediaEntry?
    public var position : Int64 = 0
    public var shouldAutoPlay = false
}


