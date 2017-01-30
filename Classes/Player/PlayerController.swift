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

class PlayerController: NSObject, Player {
    
    // reachability
    let reachabilityManager = ReachabilityManager.shared
    
    public var duration: Double {
        get {
            guard let currentPlayer = self.currentPlayer else {
                PKLog.error("currentPlayer is empty")
                return 0
            }
            
            return (currentPlayer.duration)
        }
    }
    
    public var isPlaying: Bool {
        get {
            guard let currentPlayer = self.currentPlayer else {
                PKLog.error("currentPlayer is empty")
                return false
            }
            
            return (currentPlayer.isPlaying)
        }
    }

    var onEventBlock: ((PKEvent)->Void)?
    
    var delegate: PlayerDelegate?
    
    private var currentPlayer: AVPlayerEngine?
    private var assetBuilder: AssetBuilder?
    
    public var currentTime: TimeInterval {
        get {
            if let player = self.currentPlayer {
                return player.currentPosition
            }
            
            return 0
        }
        set {
            if let player = self.currentPlayer {
                player.currentPosition = currentTime
            } else {
                PKLog.error("currentPlayer is empty")
            }
        }
    }
    
    public var currentAudioTrack: String? {
        get {
            return self.currentPlayer?.currentAudioTrack
        }
    }
    
    public var currentTextTrack: String? {
        get {
            return self.currentPlayer?.currentTextTrack
        }
    }
    
    public var view: UIView! {
        get {
            return self.currentPlayer?.view
        }
    }
    
    public init(mediaEntry: PlayerConfig) {
        super.init()
        self.currentPlayer = AVPlayerEngine()
        self.currentPlayer?.onEventBlock = { [unowned self] (event:PKEvent) in
            PKLog.trace("postEvent:: \(event)")
            
            if let block = self.onEventBlock {
                block(event)
            }
        }
        self.onEventBlock = nil
        
        // start reachability notifiier
        do {
            try self.reachabilityManager.startNotifier()
        } catch let e {
            PKLog.error("failed to start reachability notiifier, error: \(e)")
        }
    }
    
    func prepare(_ config: PlayerConfig) {
        if let player = self.currentPlayer {
            player.startPosition = config.startTime

            if let mediaEntry: MediaEntry = config.mediaEntry {
                // start reachability notifiying before loading asset to the player.
                // observe reachability and make sure to remove old observer in case prepare gets called more than once by mistake.
                NotificationCenter.default.removeObserver(self, name: .ReachabilityChanged, object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(notification:)), name: .ReachabilityChanged, object: nil)
                
                self.assetBuilder = AssetBuilder(mediaEntry: mediaEntry)
                self.assetBuilder?.build(readyCallback: { (error: Error?, asset: AVAsset?) in
                    if let avAsset: AVAsset = asset {
                        self.currentPlayer?.asset = avAsset
                    }
                })
            } else {
                PKLog.warning("mediaEntry is empty")
            }
        } else {
            PKLog.error("player is empty")
        }
    }
    
    func play() {
        PKLog.trace("play::")
        self.currentPlayer?.play()
    }
    
    func pause() {
        PKLog.trace("pause::")
        self.currentPlayer?.pause()
    }
    
    func resume() {
        PKLog.trace("resume::")
        self.currentPlayer?.play()
    }
    
    func seek(to time: CMTime) {
        PKLog.trace("seek::\(time)")
        self.currentPlayer?.currentPosition = CMTimeGetSeconds(time)
    }
    
    func prepareNext(_ config: PlayerConfig) -> Bool {
        return false
    }
    
    func loadNext() -> Bool {
        return false
    }
    
    @available(iOS 9.0, *)
    func createPiPController(with delegate: AVPictureInPictureControllerDelegate) -> AVPictureInPictureController? {
        return self.currentPlayer?.createPiPController(with: delegate)
    }
    
    func destroy() {
        self.reachabilityManager.stopNotifier()
        NotificationCenter.default.removeObserver(self, name: .ReachabilityChanged, object: nil)
        self.currentPlayer?.destroy()
    }
    
    func addObserver(_ observer: AnyObject, events: [PKEvent.Type], block: @escaping (PKEvent) -> Void) {
        //Assert.shouldNeverHappen();
    }
    
    func removeObserver(_ observer: AnyObject, events: [PKEvent.Type]) {
        //Assert.shouldNeverHappen();
    }
    
    public func selectTrack(trackId: String) {
        self.currentPlayer?.selectTrack(trackId: trackId)
    }
    
    // MARK: Reachability Changed
    
    @objc func reachabilityChanged(notification: Notification) {
        let reachability = notification.object as! Reachability
        if !reachability.isReachable {
            self.sendReachabilityErrorEvent()
        }
    }
    
    private func sendReachabilityErrorEvent() {
        if let block = self.onEventBlock {
            block(PlayerEvent.Error(error: ReachabilityError.unreachable.asNSError))
        }
    }
}
