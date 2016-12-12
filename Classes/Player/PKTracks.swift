//
//  PKTracks.swift
//  Pods
//
//  Created by Eliza Sapir on 05/12/2016.
//
//

import Foundation

public class PKTracks {
    public var audioTracks: [Track]?
    public var textTracks: [Track]?
    
    init(audioTracks: [Track]?, textTracks: [Track]?) {
        PKLog.debug("init::")
        self.audioTracks = audioTracks
        self.textTracks = textTracks
    }
}

