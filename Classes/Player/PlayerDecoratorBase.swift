//
//  PlayerDecoratorBase.swift
//  Pods
//
//  Created by Vadim Kononov on 09/11/2016.
//
//

import Foundation
import AVFoundation
import AVKit

class PlayerDecoratorBase: Player {
  
    private var player: Player!
    
    public var delegate: PlayerDelegate? {
        get {
            return self.player.delegate
        }
        set {
            self.player.delegate = newValue
        }
    }

    public var currentTime: TimeInterval? {
        get {
            return self.player.currentTime
        }
        set {
            self.player.currentTime = newValue
        }
    }
    
    public var duration: Double {
        get {
            return self.player.duration
        }
    }
    
    public var view: UIView! {
        get {
            return self.player.view
        }
    }
    
    public func prepare(_ config: PlayerConfig) {
        return self.player.prepare(config)
    }

    public func prepareNext(_ config: PlayerConfig) -> Bool {
        return self.player.prepareNext(config)
    }
    
    public func loadNext() -> Bool {
        return self.player.loadNext()
    }
    
    public func setPlayer(_ player: Player!) {
        self.player = player
    }
    
    public func getPlayer() -> Player {
        return self.player
    }
    
    public func destroy() {
        
    }
    
    public func play() {
        self.player.play()
    }
    
    public func pause() {
        self.player.pause()
    }
    
    public func seek(to time: CMTime) {
        self.player.seek(to: time)
    }
    
    public func resume() {
        self.player.resume()
    }
    
    @available(iOS 9.0, *)
    func createPiPController(with delegate: AVPictureInPictureControllerDelegate) -> AVPictureInPictureController? {
        return self.player.createPiPController(with: delegate)
    }
    
    public func addObserver(_ observer: AnyObject, event: PKEvent, block: @escaping (_ info: Any)->Void) {
        //Assert.shouldNeverHappen();
    }
    
    public func removeObserver(_ observer: AnyObject, event: PKEvent) {
        //Assert.shouldNeverHappen();
    }
}
