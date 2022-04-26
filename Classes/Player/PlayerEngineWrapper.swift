

import Foundation

public class PlayerEngineWrapper: NSObject, PlayerEngine {
    
    public var playerEngine: PlayerEngine?
    
    public var onEventBlock: ((PKEvent) -> Void)? {
        get {
            return playerEngine?.onEventBlock
        }
        set {
            playerEngine?.onEventBlock = newValue
        }
    }
    
    public var startPosition: TimeInterval {
        get {
            return playerEngine?.startPosition ?? 0.0
        }
        set {
            playerEngine?.startPosition = newValue
        }
    }
    
    public var currentPosition: TimeInterval {
        get {
            return playerEngine?.currentPosition ?? 0.0
        }
        set {
            playerEngine?.currentPosition = newValue
        }
    }
    
    public var mediaConfig: MediaConfig? {
        get {
            return playerEngine?.mediaConfig
        }
        set {
            playerEngine?.mediaConfig = newValue
        }
    }
    
    public var playbackType: String? {
        return playerEngine?.playbackType
    }
    
    public var duration: TimeInterval {
        return playerEngine?.duration ?? 0.0
    }
    
    public var currentState: PlayerState {
        return playerEngine?.currentState ?? .unknown
    }
    
    public var isPlaying: Bool {
        return playerEngine?.isPlaying ?? false
    }
    
    public var view: PlayerView? {
        get {
            return playerEngine?.view
        }
        set {
            playerEngine?.view = newValue
        }
    }
    
    public var currentTime: TimeInterval {
        get {
            return playerEngine?.currentTime ?? 0.0
        }
        set {
            playerEngine?.currentTime = newValue
        }
    }
    
    public var currentProgramTime: Date? {
        return playerEngine?.currentProgramTime
    }
    
    public var currentAudioTrack: String? {
        return playerEngine?.currentAudioTrack
    }
    
    public var currentTextTrack: String? {
        return playerEngine?.currentTextTrack
    }
    
    public var rate: Float {
        get {
            return playerEngine?.rate ?? 0.0
        }
        set {
            playerEngine?.rate = newValue
        }
    }
    
    public var volume: Float {
        get {
            return playerEngine?.volume ?? 0.0
        }
        set {
            playerEngine?.volume = newValue
        }
    }
    
    public var loadedTimeRanges: [PKTimeRange]? {
        return playerEngine?.loadedTimeRanges
    }
    
    public var bufferedTime: TimeInterval {
        return playerEngine?.bufferedTime ?? self.currentTime
    }
    
    public func loadMedia(from mediaSource: PKMediaSource?, handler: AssetHandler) {
        playerEngine?.loadMedia(from: mediaSource, handler: handler)
    }
    
    public func playFromLiveEdge() {
        playerEngine?.playFromLiveEdge()
    }
    
    public func updateTextTrackStyling(_ textTrackStyling: PKTextTrackStyling) {
        playerEngine?.updateTextTrackStyling(textTrackStyling)
    }
    
    public func play() {
        playerEngine?.play()
    }
    
    public func pause() {
        playerEngine?.pause()
    }
    
    public func resume() {
        playerEngine?.resume()
    }
    
    public func stop() {
        playerEngine?.stop()
    }
    
    public func replay() {
        playerEngine?.replay()
    }
    
    public func seek(to time: TimeInterval) {
        playerEngine?.seek(to: time)
    }
    
    public func seekToLiveEdge() {
        playerEngine?.seekToLiveEdge()
    }
    
    public func selectTrack(trackId: String) {
        playerEngine?.selectTrack(trackId: trackId)
    }
    
    public func destroy() {
        playerEngine?.destroy()
    }
    
    public func prepare(_ config: MediaConfig) {
        playerEngine?.prepare(config)
    }
    
    public func startBuffering() {
        playerEngine?.startBuffering()
    }
}
