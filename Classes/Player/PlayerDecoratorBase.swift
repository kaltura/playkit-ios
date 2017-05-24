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

@objc public class PlayerDecoratorBase: NSObject, Player {
    
    fileprivate var player: Player!
    
    public var delegate: PlayerDelegate? {
        get {
            return self.player.delegate
        }
        set {
            self.player.delegate = newValue
        }
    }

    weak public var mediaEntry: MediaEntry? {
        return self.player.mediaEntry
    }
    
    public var settings: PlayerSettings {
        return self.player.settings
    }
    
    public var currentTime: TimeInterval {
        get {
            return self.player.currentTime
        }
        set {
            self.player.currentTime = newValue
        }
    }
    
    public var duration: Double {
        return self.player.duration
    }
    
    public var currentAudioTrack: String? {
        return self.player.currentAudioTrack
    }

    public var currentTextTrack: String? {
        return self.player.currentTextTrack
    }
    
    public var isPlaying: Bool {
        return self.player.isPlaying
    }
    
    public var view: PlayerView {
        return self.player.view
    }
    
    public var sessionId: String {
        return self.player.sessionId
    }
    
    public var rate: Float {
        return self.player.rate
    }
    
    public func prepare(_ config: MediaConfig) {
        return self.player.prepare(config)
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
    
    public func stop() {
        self.player.stop()
    }
    
    public func updatePluginConfig(pluginName: String, config: Any) {
        self.player.updatePluginConfig(pluginName: pluginName, config: config)
    }
    
    public func addObserver(_ observer: AnyObject, event: PKEvent.Type, block: @escaping (PKEvent) -> Void) {
        //Assert.shouldNeverHappen();
    }
    
    public func addObserver(_ observer: AnyObject, events: [PKEvent.Type], block: @escaping (PKEvent) -> Void) {
        //Assert.shouldNeverHappen();
    }
    
    public func removeObserver(_ observer: AnyObject, event: PKEvent.Type) {
        //Assert.shouldNeverHappen();
    }
    
    public func removeObserver(_ observer: AnyObject, events: [PKEvent.Type]) {
        //Assert.shouldNeverHappen();
    }
    
    public func selectTrack(trackId: String) {
        self.player.selectTrack(trackId: trackId)
    }
}

/************************************************************/
// MARK: - iOS Only
/************************************************************/

#if os(iOS)
    extension PlayerDecoratorBase {
        
        @available(iOS 9.0, *)
        public func createPiPController(with delegate: AVPictureInPictureControllerDelegate) -> AVPictureInPictureController? {
            return self.player.createPiPController(with: delegate)
        }
    }
#endif

