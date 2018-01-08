// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import Foundation
import AVFoundation
import AVKit

@objc open class PlayerDecoratorBase: NSObject, Player {
    
    fileprivate var player: Player!
    
    public var delegate: PlayerDelegate? {
        get {
            return self.player.delegate
        }
        set {
            self.player.delegate = newValue
        }
    }

    weak public var mediaEntry: PKMediaEntry? {
        return self.player.mediaEntry
    }
    
    public var settings: PKPlayerSettings {
        return self.player.settings
    }
    
    public var mediaFormat: PKMediaSource.MediaFormat {
        return self.player.mediaFormat
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
    
    open var currentState: PlayerState {
        return self.player.currentState
    }
    
    open var isPlaying: Bool {
        return self.player.isPlaying
    }
    
    public weak var view: PlayerView? {
        get {
            return self.player.view
        }
        set {
            self.player.view = newValue
        }
    }
    
    public var sessionId: String {
        return self.player.sessionId
    }
    
    public var rate: Float {
        get {
            return self.player.rate
        }
        set {
            self.player.rate = newValue
        }
    }
    
    @objc public var loadedTimeRanges: [PKTimeRange]? {
        return self.player.loadedTimeRanges
    }
    
    open func prepare(_ config: MediaConfig) {
        self.player.prepare(config)
    }
    
    public func setPlayer(_ player: Player!) {
        self.player = player
    }
    
    public func getPlayer() -> Player {
        return self.player
    }
    
    open func destroy() {
        self.player.destroy()
    }
    
    open func play() {
        self.player.play()
    }
    
    open func pause() {
        self.player.pause()
    }
    
    open func seek(to time: TimeInterval) {
        self.player.seek(to: time)
    }
    
    open func resume() {
        self.player.resume()
    }
    
    open func stop() {
        self.player.stop()
    }
    
    public func updatePluginConfig(pluginName: String, config: Any) {
        self.player.updatePluginConfig(pluginName: pluginName, config: config)
    }
    
    public func isLive() -> Bool {
        return self.player.isLive()
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
    
    public func getController(type: PKController.Type) -> PKController? {
        return self.player.getController(type: type)
    }
    
    public func addPeriodicObserver(interval: TimeInterval, observeOn dispatchQueue: DispatchQueue? = nil, using block: @escaping (TimeInterval) -> Void) -> UUID {
        return self.player.addPeriodicObserver(interval: interval, observeOn: dispatchQueue, using: block)
    }
    
    public func addBoundaryObserver(boundaries: [PKBoundary], observeOn dispatchQueue: DispatchQueue? = nil, using block: @escaping (TimeInterval, Double) -> Void) -> UUID {
        return self.player.addBoundaryObserver(boundaries: boundaries, observeOn: dispatchQueue, using: block)
    }
    
    public func removePeriodicObserver(_ token: UUID) {
        self.player.removePeriodicObserver(token)
    }
    
    public func removeBoundaryObserver(_ token: UUID) {
        self.player.removeBoundaryObserver(token)
    }
}
