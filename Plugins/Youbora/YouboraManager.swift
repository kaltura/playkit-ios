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
    var currentBitrate: Double?
    
    init(options: NSObject!, player: Player) {
        super.init(options: options)
        self.pkPlayer = player
    }
    
    // we must override this init in order to add our init (happens because of interopatability of youbora objc framework with swift). 
    private override init() {
        super.init()
    }
    
    /************************************************************/
    // MARK: - Youbora Info Methods
    /************************************************************/
    
    override func getMediaDuration() -> NSNumber! {
        let duration = self.pkPlayer?.duration
        return duration != nil ? NSNumber(value: duration!) : super.getMediaDuration()
    }
    
    override func getResource() -> String! {
        return self.pkPlayer?.mediaEntry?.id ?? "" // FIXME: make sure to expose player content url and use it here instead of id
    }
    
    override func getTitle() -> String! {
        return self.pkPlayer?.mediaEntry?.id ?? ""
    }
    
    override func getPlayhead() -> NSNumber! {
        let currentTime = self.pkPlayer?.currentTime
        return currentTime != nil ? NSNumber(value: currentTime!) : super.getPlayhead()
    }
    
    override func getPlayerVersion() -> String! {
        return "\(PlayKitManager.clientTag)"
    }
    
    override func getBitrate() -> NSNumber! {
        if let bitrate = currentBitrate {
            return NSNumber(value: bitrate)
        }
        return super.getBitrate()
    }
}
