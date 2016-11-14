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

class PlayerDecoratorBase: Player, PlayerDataSource, PlayerDelegate {
    
    private var player: Player!
    
    var dataSource: PlayerDataSource? {
        didSet {
            self.player.dataSource = self
        }
    }
    
    var delegate: PlayerDelegate? {
        didSet {
            self.player.delegate = self
        }
    }
        
    public var currentTime: TimeInterval? {
        get {
            return self.player.currentTime
        }
        set {
            self.player.currentTime = currentTime
        }
    }
    
    public var view: UIView! {
        get {
            return self.player.view
        }
    }
    
    public var playerEngine: PlayerEngine? {
        get {
            return self.player.playerEngine
        }
    }

    public var autoPlay: Bool? {
        get {
            return self.player.autoPlay
        }
        set {
            self.player.autoPlay = autoPlay
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
    
    public func destroy() {
        self.player.destroy()
    }
    
    public func addBoundaryTimeObserver(origin: Origin, offset: TimeInterval, wait: Bool, observer: TimeObserver) {
        self.player.addBoundaryTimeObserver(origin: origin, offset: offset, wait: wait, observer: observer)
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
    
    //MARK: Player DataSource methods
        
    func playerCanPlayAd(_ player: Player) -> Bool {
        return self.dataSource!.playerCanPlayAd(self)
    }
    
    //MARK: Player Delegate methods
    
    func player(_ player: Player, failedWith error: String) {
        self.delegate?.player(self, failedWith: error)
    }
    
    func player(_ player: Player, didReceive event: PlayerEventType, with eventData: Any?) {
        self.delegate?.player(self, didReceive: event, with: eventData)
    }
}
