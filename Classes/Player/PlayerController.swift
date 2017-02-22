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
    var onEventBlock: ((PKEvent)->Void)?
    
    var delegate: PlayerDelegate?
    
    fileprivate var currentPlayer: AVPlayerEngine?
    fileprivate var assetBuilder: AssetBuilder?
    
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
    
    public override init() {
        super.init()
        self.currentPlayer = AVPlayerEngine()
        self.currentPlayer?.onEventBlock = { [weak self] event in
            PKLog.trace("postEvent:: \(event)")
            self?.onEventBlock?(event)
        }
        self.onEventBlock = nil
    }
    
    // Every player that is created should own Reachability instance
    let reachability = Reachability()
    var shouldRefresh: Bool = false
    
    func prepare(_ config: MediaConfig) {
        if let player = self.currentPlayer {
            player.startPosition = config.startTime

            if let mediaEntry: MediaEntry = config.mediaEntry {
                self.assetBuilder = AssetBuilder(mediaEntry: mediaEntry)
                self.assetBuilder?.build(readyCallback: { (error: Error?, asset: AVAsset?) in
                    if let avAsset: AVAsset = asset {
                        self.currentPlayer?.asset = avAsset
                        
                        if DRMSupport.widevineClassicHandler != nil {
                            self.addAssetRefreshObservers()
                        }
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
    
    func prepareNext(_ config: MediaConfig) -> Bool {
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
        self.currentPlayer?.destroy()
        self.removeAssetRefreshObservers()
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
}

/************************************************************/
// MARK: - Reachability & Application States Handling
/************************************************************/
extension PlayerController {
    private func prepareToRefreshAsset() {
        if let handler = self.assetBuilder?.assetHandler as? RefreshableAssetHandler {
            if let (source, handlerClass) = self.assetBuilder!.getPreferredMediaSource() {
                handler.prepareToRefreshAsset(mediaSource: source, refreshCallback: { [unowned self](shouldRefresh) in
                    if shouldRefresh {
                        self.shouldRefresh = true
                    }
                })
            }
        }
    }
    
    private func refreshAsset() {
        if let handler = self.assetBuilder?.assetHandler as? RefreshableAssetHandler {
            
            if let (source, handlerClass) = self.assetBuilder!.getPreferredMediaSource() {
                self.currentPlayer?.startPosition = (self.currentPlayer?.currentPosition)!
                handler.refreshAsset(mediaSource: source)
            }
        }
    }
    
    func addAssetRefreshObservers() {
        self.addReachabilityObserver()
        self.addAppStateChangeObserver()
        self.prepareToRefreshAsset()
    }
    
    func removeAssetRefreshObservers() {
        self.removeReachabilityObserver()
        self.removeAppStateChangeObserver()
    }
    
    // Reachability Handling
    private func addReachabilityObserver() -> Void {
        self.reachability?.startNotifier()
        
        self.reachability?.onReachable = { [unowned self] reachability in
            self.handleRefreshAsset()
        }
    }
    
    private func removeReachabilityObserver() -> Void {
        self.reachability?.stopNotifier()
    }
    
    private func sendReachabilityErrorEvent() {
        if let block = self.onEventBlock {
            PKLog.error("unreachable");
            // TODO: error handling
        }
    }
    
    // Application States Handling
    private func addAppStateChangeObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(PlayerController.applicationDidBecomeActive),
                                               name: .UIApplicationDidBecomeActive,
                                               object: nil)
    }
    
    private func removeAppStateChangeObserver() {
        NotificationCenter.default.removeObserver(self,
                                                  name: .UIApplicationDidBecomeActive,
                                                  object: nil)
    }
    
    @objc private func applicationDidBecomeActive() {
        self.handleRefreshAsset()
    }
    
    private func handleRefreshAsset() {
        if self.shouldRefresh {
            self.shouldRefresh = false
            self.refreshAsset()
        }
    }
}
