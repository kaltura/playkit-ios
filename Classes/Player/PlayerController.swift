//
//  PlayerController.swift
//  Pods
//
//  Created by Eliza Sapir on 06/11/2016.
//
//

import Foundation
import AVFoundation
import AVKit

class PlayerController: Player {
    
    var dataSource: PlayerDataSource?
    var delegate: PlayerDelegate?
    
    private var currentPlayer: PlayerEngine?
    private var allowPlayerEngineExpose: Bool = false
    
    public var playerEngine: PlayerEngine? {
        get {
            return allowPlayerEngineExpose ? currentPlayer : nil
        }
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

    public init() {
        currentPlayer = AVPlayerEngine()
    }

    func prepare(_ config: PlayerConfig) {
        currentPlayer?.prepareNext(config)
        allowPlayerEngineExpose = config.allowPlayerEngineExpose
    }
    
    func play() {
        self.currentPlayer?.play()
    }

    func pause() {
        self.currentPlayer?.pause()
    }

    func resume() {
        self.currentPlayer?.play()
    }
    
    func seek(to time: CMTime) {
        self.currentPlayer?.seek(to: time)
    }
    
    func prepareNext(_ config: PlayerConfig) -> Bool {
        return false
    }

    func loadNext() -> Bool {
        return false
    }
    
    func addBoundaryTimeObserver(origin: Origin, offset: TimeInterval, wait: Bool, observer: TimeObserver) {
        
    }
    
    @available(iOS 9.0, *)
    func createPiPController(with delegate: AVPictureInPictureControllerDelegate) -> AVPictureInPictureController? {
        if let avPlayerLayer = self.currentPlayer?.layer as? AVPlayerLayer {
            let pip = AVPictureInPictureController(playerLayer: avPlayerLayer)
            pip?.delegate = delegate
            return pip
        }
        return nil
    }
    
    func destroy() {
        self.currentPlayer?.destroy()
    }
}
