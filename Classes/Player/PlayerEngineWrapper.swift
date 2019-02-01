//
//  PlayerEngineWrapper.swift
//  PlayKit
//
//  Created by Nilit Danan on 1/28/19.
//

import Foundation

public class PlayerEngineWrapper: PlayerEngine {
    
    public private(set) var playerEngine: PlayerEngine
    
    init(playerEngine: PlayerEngine) {
        self.playerEngine = playerEngine
    }
    
    public var onEventBlock: ((PKEvent) -> Void)? {
        get {
            return playerEngine.onEventBlock
        }
        set {
            playerEngine.onEventBlock = newValue
        }
    }
    
    public var startPosition: TimeInterval {
        get {
            return playerEngine.startPosition
        }
        set {
            playerEngine.startPosition = newValue
        }
    }
    
    public var currentPosition: TimeInterval {
        get {
            return playerEngine.currentPosition
        }
        set {
            playerEngine.currentPosition = newValue
        }
    }
    
    public var mediaConfig: MediaConfig? {
        get {
            return playerEngine.mediaConfig
        }
        set {
            playerEngine.mediaConfig = newValue
        }
    }
    
    public var playbackType: String? {
        return playerEngine.playbackType
    }
    
    public var duration: TimeInterval {
        return playerEngine.duration
    }
    
    public var currentState: PlayerState {
        return playerEngine.currentState
    }
    
    public var isPlaying: Bool {
        return playerEngine.isPlaying
    }
    
    public var view: PlayerView? {
        get {
            return playerEngine.view
        }
        set {
            playerEngine.view = newValue
        }
    }
    
    public var currentTime: TimeInterval {
        get {
            return playerEngine.currentTime
        }
        set {
            playerEngine.currentTime = newValue
        }
    }
    
    public var currentProgramTime: Date? {
        return playerEngine.currentProgramTime
    }
    
    public var currentAudioTrack: String? {
        return playerEngine.currentAudioTrack
    }
    
    public var currentTextTrack: String? {
        return playerEngine.currentTextTrack
    }
    
    public var rate: Float {
        get {
            return playerEngine.rate
        }
        set {
            playerEngine.rate = newValue
        }
    }
    
    public var loadedTimeRanges: [PKTimeRange]? {
        return playerEngine.loadedTimeRanges
    }
    
    public func loadMedia(from mediaSource: PKMediaSource?, handler: AssetHandler) {
        playerEngine.loadMedia(from: mediaSource, handler: handler)
    }
    
    public func playFromLiveEdge() {
        playerEngine.playFromLiveEdge()
    }
    
    public func play() {
        playerEngine.play()
    }
    
    public func pause() {
        playerEngine.pause()
    }
    
    public func resume() {
        playerEngine.resume()
    }
    
    public func stop() {
        playerEngine.stop()
    }
    
    public func replay() {
        playerEngine.replay()
    }
    
    public func seek(to time: TimeInterval) {
        playerEngine.seek(to: time)
    }
    
    public func selectTrack(trackId: String) {
        playerEngine.selectTrack(trackId: trackId)
    }
    
    public func destroy() {
        playerEngine.destroy()
    }
    
    public func prepare(_ config: MediaConfig) {
        playerEngine.prepare(config)
    }
}
