//
//  PlayerController.swift
//  Pods
//
//  Created by Eliza Sapir on 06/11/2016.
//
//

import Foundation

class PlayerController: Player {
    
    var dataSource: PlayerDataSource?
    
    /**
     Get the player's View component.
     */
    public var view: UIView?    
    private var currentPlayer: PlayerEngine?
    
    public init() {
        currentPlayer = AVPlayerEngine()
    }

    func load(_ config: PlayerConfig) -> Bool {
        currentPlayer?.prepareNext(config)
        return false
    }

    func apply(_ config: PlayerConfig) -> Bool {
        return false
    }
    
    public var autoPlay: Bool? {
        get {
            return false
          //  return
        }
        set {
            //
        }
    }

    func play() {
        self.currentPlayer?.play()
    }

    func pause() {
        self.currentPlayer?.pause()
    }

    func prepareNext(_ config: PlayerConfig) -> Bool {
        return false
    }

    func loadNext() -> Bool {
        return false
    }
    
    public var currentTime: TimeInterval? {
        get {
            //  return
            return self.currentPlayer?.currentPosition
        }
        set {
            //
        }
    }
    
    public var layer: CALayer! {
        get {
            return self.currentPlayer?.layer
        }
    }
    
    func addBoundaryTimeObserver(origin: Origin, offset: TimeInterval, wait: Bool, observer: TimeObserver) {
        
    }
}
