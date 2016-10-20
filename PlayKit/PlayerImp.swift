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
    
    public var shouldPlayWhenReady: Bool = false {
        
        didSet {
            print("shouldPlayWhenReady has changed from \(oldValue) to \(shouldPlayWhenReady)")
            if shouldPlayWhenReady {
                // TODO: play
            } else {
                // TODO: pause
            }
        }
    }
    
    public func pause() {
        shouldPlayWhenReady = false
    }

    public func play() {
        shouldPlayWhenReady = true
    }

    
    init() {
        // TODO
    }
    
    
    
    public var position: TimeInterval {
        set {
            // TODO: set position
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
