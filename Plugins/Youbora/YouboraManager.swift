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
    private var mediaEntry: MediaEntry!
    
    init!(options: NSObject!, player: Player, media: MediaEntry) {
        super.init(options: options)
        self.pkPlayer = player
        self.mediaEntry = media
    }
    
    override init() {
        super.init()
    }
    
    //MARK: Override methods
    override func getMediaDuration() -> NSNumber! {
        return pkPlayer.duration as NSNumber!
    }
    
    override func getResource() -> String! {
        PKLog.trace("Resource")

        if let title = self.mediaEntry.id {
            return title
        }
        return ""
    }
    
    override func getPlayhead() -> NSNumber! {
        let currentTIme = self.pkPlayer.currentTime
        PKLog.trace("Current time: \(currentTIme)")
        return currentTIme as NSNumber!
    }
    
    override func getPlayerVersion() -> String! {
        return "PlayKit-0.1.0"
    }
}
