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
    
    // for some reason we must implement the initializer this way because the way youbora implemented the init.
    // this means player and media entry are defined as optionals but they must have values when initialized.
    // All the checks for optionals in this class are just because we defined them as optionals but they are not so the checks are irrelevant.
    convenience init!(options: NSObject!, player: Player) {
        self.init(options: options)
        self.pkPlayer = player
    }
    
    /************************************************************/
    // MARK: - Overrides
    /************************************************************/
    
    override func getMediaDuration() -> NSNumber! {
        let duration = self.pkPlayer?.duration
        return duration != nil ? NSNumber(value: duration!) : super.getMediaDuration()
    }
    
    override func getResource() -> String! {
        return self.pkPlayer?.mediaEntry?.id ?? "" // FIXME: create new content url property or event id is not correct here.
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
