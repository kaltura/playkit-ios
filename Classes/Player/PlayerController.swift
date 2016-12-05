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
    
    public var duration: Double {
        get {
            return (self.currentPlayer?.duration)!
        }
    }

    var onEventBlock: ((PKEvent)->Void)?
    
    var delegate: PlayerDelegate?
    
    private var currentPlayer: AVPlayerEngine?
    private var assetBuilder: AssetBuilder?
    
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
            self.currentPlayer?.currentPosition = currentTime!
        }
    }
    
    public var view: UIView! {
        get {
            return self.currentPlayer?.view
        }
    }
    
    public init(mediaEntry: PlayerConfig) {
        self.currentPlayer = AVPlayerEngine()
        self.currentPlayer?.onEventBlock = { (event:PKEvent) in
            PKLog.trace("postEvent:: \(event)")
            
            if let block = self.onEventBlock {
                block(event)
            }
        }
        
        self.onEventBlock = nil
    }
    
    func prepare(_ config: PlayerConfig) {
        if let mediaEntry: MediaEntry = config.mediaEntry  {
            self.assetBuilder = AssetBuilder(mediaEntry: mediaEntry)
            self.assetBuilder?.build(readyCallback: { (error: Error?, asset: AVAsset?) in
                if let avAsset: AVAsset = asset {
                    self.currentPlayer?.asset = avAsset
                }
            })
        } else {
            PKLog.warning("mediaEntry is empty")
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
//        self.currentPlayer?.seek(to: time)
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
        self.currentPlayer?.destroy()
    }
    
    func addObserver(_ observer: AnyObject, events: [PKEvent.Type], block: @escaping (Any) -> Void) {
        //Assert.shouldNeverHappen();
    }
    
    func removeObserver(_ observer: AnyObject, events: [PKEvent.Type]) {
        //Assert.shouldNeverHappen();
    }
}
