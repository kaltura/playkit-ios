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
    
    weak var delegate: PlayerDelegate?
    
    fileprivate var currentPlayer: AVPlayerEngine
    fileprivate var assetBuilder: AssetBuilder?
    
    public var mediaEntry: MediaEntry? {
        return self.assetBuilder?.mediaEntry
    }
    
    public var duration: Double {
        return self.currentPlayer.duration
    }
    
    public var isPlaying: Bool {
        return self.currentPlayer.isPlaying
    }

    public var currentTime: TimeInterval {
        get { return self.currentPlayer.currentPosition }
        set { self.currentPlayer.currentPosition = newValue }
    }
    
    public var currentAudioTrack: String? {
        return self.currentPlayer.currentAudioTrack
    }
    
    public var currentTextTrack: String? {
        return self.currentPlayer.currentTextTrack
    }
    
    public var view: UIView! {
        return self.currentPlayer.view
    }
    
    public override init() {
        self.currentPlayer = AVPlayerEngine()
        super.init()
        self.currentPlayer.onEventBlock = { [weak self] event in
            PKLog.trace("postEvent:: \(event)")
            self?.onEventBlock?(event)
        }
        self.onEventBlock = nil
    }
    
    // Every player that is created should own Reachability instance
    let reachability = PKReachability()
    var shouldRefresh: Bool = false
    
    func prepare(_ config: MediaConfig) {
        self.currentPlayer.startPosition = config.startTime
        self.assetBuilder = AssetBuilder(mediaEntry: config.mediaEntry)
        self.assetBuilder?.build { (error: Error?, asset: AVAsset?) in
            if let avAsset: AVAsset = asset {
                self.currentPlayer.asset = avAsset
                if DRMSupport.widevineClassicHandler != nil {
                    self.addAssetRefreshObservers()
                }
            }
        }
    }
    
    func play() {
        PKLog.trace("play::")
        self.currentPlayer.play()
    }
    
    func pause() {
        PKLog.trace("pause::")
        self.currentPlayer.pause()
    }
    
    func resume() {
        PKLog.trace("resume::")
        self.currentPlayer.play()
    }
    
    func stop() {
        PKLog.trace("stop::")
        self.currentPlayer.stop()
    }
    
    func seek(to time: CMTime) {
        PKLog.trace("seek::\(time)")
        self.currentPlayer.currentPosition = CMTimeGetSeconds(time)
    }
    
    @available(iOS 9.0, *)
    func createPiPController(with delegate: AVPictureInPictureControllerDelegate) -> AVPictureInPictureController? {
        return self.currentPlayer.createPiPController(with: delegate)
    }
    
    func destroy() {
        self.currentPlayer.destroy()
        self.removeAssetRefreshObservers()
    }
    
    func addObserver(_ observer: AnyObject, events: [PKEvent.Type], block: @escaping (PKEvent) -> Void) {
        //Assert.shouldNeverHappen();
    }
    
    func removeObserver(_ observer: AnyObject, events: [PKEvent.Type]) {
        //Assert.shouldNeverHappen();
    }
    
    public func selectTrack(trackId: String) {
        self.currentPlayer.selectTrack(trackId: trackId)
    }
}

/************************************************************/
// MARK: - Reachability & Application States Handling
/************************************************************/
extension PlayerController {
    private func shouldRefreshAsset() {
        if let handler = self.assetBuilder?.assetHandler as? RefreshableAssetHandler {
            if let (source, handlerClass) = self.assetBuilder!.getPreferredMediaSource() {
                handler.shouldRefreshAsset(mediaSource: source) { [unowned self] (shouldRefresh) in
                    if shouldRefresh {
                        self.shouldRefresh = true
                    }
                }
            }
        }
    }
    
    private func refreshAsset() {
        if let handler = self.assetBuilder?.assetHandler as? RefreshableAssetHandler {
            
            if let (source, handlerClass) = self.assetBuilder!.getPreferredMediaSource() {
                self.currentPlayer.startPosition = self.currentPlayer.currentPosition
                handler.refreshAsset(mediaSource: source)
            }
        }
    }
    
    func addAssetRefreshObservers() {
        self.addReachabilityObserver()
        self.addAppStateChangeObserver()
        self.shouldRefreshAsset()
    }
    
    func removeAssetRefreshObservers() {
        self.removeReachabilityObserver()
        self.removeAppStateChangeObserver()
    }
    
    // Reachability Handling
    private func addReachabilityObserver() -> Void {
        guard let reachability = self.reachability else { return }
        reachability.startNotifier()
        
        reachability.onUnreachable = { reachability in
            PKLog.warning("network unreachable")
        }
        reachability.onReachable = { [unowned self] reachability in
            self.handleRefreshAsset()
        }
    }
    
    private func removeReachabilityObserver() -> Void {
        self.reachability?.stopNotifier()
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
