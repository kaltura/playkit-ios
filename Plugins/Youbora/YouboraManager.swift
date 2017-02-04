//
//  YouboraManager.swift
//  Pods
//
//  Created by Oded Klein on 28/11/2016.
//
//

import YouboraLib
import YouboraPluginAVPlayer
import Foundation
import UIKit
import AVFoundation
import AVKit

class YouboraManager: YBPluginGeneric {

    private var pkPlayer: Player!
    var mediaEntry: MediaEntry!
    public var currentBitrate: Double?
    
    init!(options: NSObject!, player: Player, mediaEntry: MediaEntry) {
        super.init(options: options)
        self.pkPlayer = player
        self.mediaEntry = mediaEntry
    }
    
    private override init() {
        super.init()
    }
    
    /************************************************************/
    // MARK: - Overrides
    /************************************************************/
    
    override func getMediaDuration() -> NSNumber {
        return NSNumber(value: pkPlayer.duration)
    }
    
    override func getResource() -> String {
        PKLog.trace("Resource")
        return self.mediaEntry.id
    }
    
    override func getPlayhead() -> NSNumber {
        let currentTIme = self.pkPlayer.currentTime
        return NSNumber(value: currentTIme)
    }
    
    override func getPlayerVersion() -> String {
        return "PlayKit-\(PlayKitManager.versionString)"
    }
    
    override func getBitrate() -> NSNumber {
        if let bitrate = currentBitrate {
            return NSNumber(value: bitrate)
        }
        return NSNumber(value: 0.0)
    }
}
