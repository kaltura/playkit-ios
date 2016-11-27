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
    var eventChangedblock: ((_ event: PKEvent)->Void)?

    var delegate: PlayerDelegate?
    
    private var currentPlayer: PlayerEngine?
    private var allowPlayerEngineExpose: Bool = false
    
    public func registerEventChange(_ block: @escaping (_ event: PKEvent)->Void) {
        eventChangedblock = block;
    }
    
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
        self.eventChangedblock = nil
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
        if let block = eventChangedblock {
            eventChangedblock!(changedEvent)
        }
    }
    
    func player(encounteredError: NSError) {
        // TODO:: finilizing + object validation
        NSLog("encounteredError")
    }
    
    func addObserver(_ observer: AnyObject, event: PKEvent, block: @escaping (Any) -> Void) {
        //Assert.shouldNeverHappen();
    }
    
    func removeObserver(_ observer: AnyObject, event: PKEvent) {
        //Assert.shouldNeverHappen();
    }
}
