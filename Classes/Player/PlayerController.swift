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
    
    private var currentPlayer: AVPlayerEngine
    private var assetBuilder: AssetBuilder?
    
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
    
    func prepare(_ config: MediaConfig) {
        currentPlayer.startPosition = config.startTime
        if let mediaEntry: MediaEntry = config.mediaEntry  {
            self.assetBuilder = AssetBuilder(mediaEntry: mediaEntry)
            self.assetBuilder?.build(readyCallback: { (error: Error?, asset: AVAsset?) in
                if let avAsset: AVAsset = asset {
                    self.currentPlayer.asset = avAsset
                }
            })
        } else {
            PKLog.error("mediaEntry is empty")
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
    
    func seek(to time: CMTime) {
        PKLog.trace("seek::\(time)")
        self.currentPlayer.currentPosition = CMTimeGetSeconds(time)
    }
    
    func prepareNext(_ config: MediaConfig) -> Bool {
        return false
    }
    
    func loadNext() -> Bool {
        return false
    }
    
    @available(iOS 9.0, *)
    func createPiPController(with delegate: AVPictureInPictureControllerDelegate) -> AVPictureInPictureController? {
        return self.currentPlayer.createPiPController(with: delegate)
    }
    
    func destroy() {
        self.currentPlayer.destroy()
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
