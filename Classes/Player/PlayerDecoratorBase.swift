//
//  PlayerDecoratorBase.swift
//  Pods
//
//  Created by Vadim Kononov on 09/11/2016.
//
//

import Foundation
import AVFoundation

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
    
    public var view: UIView? {
        get {
            return self.player.view
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
    
    public var layer: CALayer! {
        get {
            return self.player.layer
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
    
    //MARK: Player DataSource methods
    
    public func playerVideoView(_ player: Player) -> UIView {
        return self.dataSource!.playerVideoView(self)
    }
    
    func playerCanPlayAd(_ player: Player) -> Bool {
        return self.dataSource!.playerCanPlayAd(self)
    }
    
    func playerCompanionView(_ player: Player) -> UIView? {
        return self.dataSource!.playerCompanionView(self)
    }
    
    func playerAdWebOpenerPresentingController(_ player: Player) -> UIViewController? {
        return self.dataSource!.playerAdWebOpenerPresentingController(self)
    }
    
    //MARK: Player Delegate methods
    
    func playerAdDidRequestContentPause(_ player: Player) {
        self.delegate?.playerAdDidRequestContentPause(self)
    }
    
    func playerAdDidRequestContentResume(_ player: Player) {
        self.delegate?.playerAdDidRequestContentPause(self)
    }
    
    func player(_ player: Player, failedWith error: String) {
        self.delegate?.player(self, failedWith: error)
    }
    
    func player(_ player: Player, didReceive event: PlayerEventType) {
        self.delegate?.player(self, didReceive: event)
    }
    
    func player(_ player: Player, adDidProgressToTime mediaTime: TimeInterval, totalTime: TimeInterval) {
        self.delegate?.player(self, adDidProgressToTime: mediaTime, totalTime: totalTime)
    }
    
    func player(_ player: Player, adWebOpenerDidOpenInAppBrowser webOpener: NSObject!) {
        self.delegate?.player(self, adWebOpenerDidOpenInAppBrowser: webOpener)
    }
    
    func player(_ player: Player, adWebOpenerDidCloseInAppBrowser webOpener: NSObject!) {
        self.delegate?.player(self, adWebOpenerDidCloseInAppBrowser: webOpener)
    }
    
    func player(_ player: Player, adWebOpenerWillOpenInAppBrowser webOpener: NSObject!) {
        self.delegate?.player(self, adWebOpenerWillOpenInAppBrowser: webOpener)
    }
    
    func player(_ player: Player, adWebOpenerWillCloseInAppBrowser webOpener: NSObject!) {
        self.delegate?.player(self, adWebOpenerWillCloseInAppBrowser: webOpener)
    }
    
    func player(_ player: Player, adWebOpenerWillOpenExternalBrowser webOpener: NSObject!) {
        self.delegate?.player(self, adWebOpenerWillOpenExternalBrowser: webOpener)
    }
}
