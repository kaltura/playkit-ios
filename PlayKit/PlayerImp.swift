//
//  PlayerImp.swift
//  PlayKit
//
//  Created by Noam Tamim on 09/10/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

import Foundation
import AVFoundation


class PlayerImp : Player {
    
    public var autoPlay: Bool = false {
        
        didSet {
            print("autoPlay has changed from \(oldValue) to \(autoPlay)")
            if autoPlay {
                // TODO: play
            } else {
                // TODO: pause
            }
        }
    }
    
    public func pause() {
        autoPlay = false
    }

    public func play() {
        autoPlay = true
    }

    
    init() {
        // TODO
    }
    
    
    
    public var currentTime: TimeInterval {
        set {
            // TODO: set current time
        }
        get {
            // TODO: return player's current time
            return 0
        }
    }
    
    public func release() {
        // TODO: release the player
    }
    
    lazy var view: UIView = {
        
        // TODO: return the view
        return UIView()
    }()
    
    
    public func load(_ config: PlayerConfig) -> Bool {
        // TODO: prepare, set fields, etc
        // load the player

        PlayKitManager.createPlugin(name: "Sample")?.load(player: self, config: config)
        
        return false
    }
    
    public func apply(_ config: PlayerConfig) -> Bool {
        // TODO: similar to load
        return false
    }
    
    func prepareNext(_ config: PlayerConfig) -> Bool {
        // TODO: similar to load, but don't play until current item ends.
        return false
    }
    
    func loadNext() -> Bool {
        // TODO: switch to the next item.
        return false
    }
    
}
