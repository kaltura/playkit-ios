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
    var messageBus = MessageBus()

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
    
    public var view: UIView! {
        get {
            return self.currentPlayer?.view
        }
    }

    public init(mediaEntry: PlayerConfig) {
        self.currentPlayer = AVPlayerEngine()
        self.currentPlayer?.delegate = self
    }

    func prepare(_ config: PlayerConfig) {
        currentPlayer?.prepareNext(config)
        allowPlayerEngineExpose = config.allowPlayerEngineExpose
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
    
    public func addObserver(_ observer: AnyObject, event: PKEvent, block: @escaping (_ info: Any)->Void) {
        // TODO:: finilizing + object validation
        messageBus.addObserver(observer, event: event, block: block)
    }
    
    public func removeObserver(_ observer: AnyObject, event: PKEvent) {
        // TODO:: finilizing + object validation
        messageBus.removeObserver(observer, event: event)
    }
    
    func player(changedState: PKEvent) {
        // TODO:: finilizing + object validation
        NSLog("changedState")
        messageBus.post(changedState)
    }
    
    func player(encounteredError: NSError) {
        // TODO:: finilizing + object validation
        NSLog("encounteredError")
    }
}
