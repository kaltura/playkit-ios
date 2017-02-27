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

    private weak var pkPlayer: Player?
    weak var mediaEntry: MediaEntry?
    public var currentBitrate: Double?
    
    // for some reason we must implement the initializer this way because the way youbora implemented the init.
    // this means player and media entry are defined as optionals but they must have values when initialized.
    // All the checks for optionals in this class are just because we defined them as optionals but they are not so the checks are irrelevant.
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
        return NSNumber(value: pkPlayer?.duration ?? 0)
    }
    
    override func getResource() -> String {
        PKLog.debug("Resource")
        return self.mediaEntry?.id ?? ""
    }
    
    override func getPlayhead() -> NSNumber {
        let currentTIme = self.pkPlayer?.currentTime ?? 0
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
