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

class PlayerController: Player, PlayerEngineDelegate {
    
    public var duration: Double {
        get {
            return (self.currentPlayer?.duration)!
        }
    }
    
    var messageBus = MessageBus()
    var onEventBlock: ((PKEvent)->Void)?
    
    var delegate: PlayerDelegate?
    
    private var currentPlayer: PlayerEngine?
    private var assetBuilder: AssetBuilder?
    
    public var currentTime: TimeInterval? {
        get {
            //  return
            return self.currentPlayer?.currentPosition
        }
        set {
            //
        }
    }
    
    public var view: UIView! {
        get {
            return self.currentPlayer?.view
        }
    }
    
    public init(mediaEntry: PlayerConfig) {
        self.currentPlayer = AVPlayerEngine()
        self.currentPlayer?.delegate = self
        self.assetBuilder = nil
        self.onEventBlock = nil
    }
    
    func prepare(_ config: PlayerConfig) {
        self.assetBuilder = AssetBuilder(config: config, readyBlock: { (asset: Any) in
            self.currentPlayer?.prepareNext(config)
        })
    }
    
    func play() {
        PKLog.trace("Enter Play")
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
    
    @available(iOS 9.0, *)
    func createPiPController(with delegate: AVPictureInPictureControllerDelegate) -> AVPictureInPictureController? {
        return self.currentPlayer?.createPiPController(with: delegate)
    }
    
    func destroy() {
        self.currentPlayer?.destroy()
    }
    
    func player(changedEvent: PKEvent) {
        // TODO:: finilizing + object validation
        NSLog("changedState")
        if let block = onEventBlock {
            block(changedEvent)
        }
    }
    
    func player(encounteredError: NSError) {
        // TODO:: finilizing + object validation
        NSLog("encounteredError")
    }
    
    func addObserver(_ observer: AnyObject, events: [PKEvent.Type], block: @escaping (Any) -> Void) {
        preconditionFailure("This method must be overridden")
    }
    
    func removeObserver(_ observer: AnyObject, events: [PKEvent.Type]) {
        preconditionFailure("This method must be overridden")
    }
}
