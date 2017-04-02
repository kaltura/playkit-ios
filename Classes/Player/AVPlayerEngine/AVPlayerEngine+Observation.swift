//
//  AVPlayerEngine+Observation.swift
//  Pods
//
//  Created by Gal Orlanczyk on 07/03/2017.
//
//

import Foundation
import AVFoundation
import CoreMedia

extension AVPlayerEngine {
    
    // An array of key paths for the properties we want to observe.
    private var observedKeyPaths: [String] {
        return [
            #keyPath(rate),
            #keyPath(currentItem.status),
            #keyPath(currentItem),
            #keyPath(currentItem.playbackLikelyToKeepUp),
            #keyPath(currentItem.playbackBufferEmpty),
            #keyPath(currentItem.duration),
            #keyPath(currentItem.timedMetadata)
        ]
    }
    
    // - Observers
    func addObservers() {
        PKLog.trace("addObservers")
        
        self.isObserved = true
        // Register observers for the properties we want to display.
        for keyPath in observedKeyPaths {
            addObserver(self, forKeyPath: keyPath, options: [.new, .initial], context: &observerContext)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerFailed(notification:)), name: .AVPlayerItemFailedToPlayToEndTime, object: self.currentItem)
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerPlayedToEnd(notification:)), name: .AVPlayerItemDidPlayToEndTime, object: self.currentItem)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onAccessLogEntryNotification), name: .AVPlayerItemNewAccessLogEntry, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onErrorLogEntryNotification), name: .AVPlayerItemNewErrorLogEntry, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.timebaseChanged), name: Notification.Name(kCMTimebaseNotification_EffectiveRateChanged as String), object: self.currentItem?.timebase)
    }
    
    func removeObservers() {
        if !self.isObserved {
            return
        }
        
        PKLog.trace("removeObservers")
        
        // Un-register observers
        for keyPath in observedKeyPaths {
            removeObserver(self, forKeyPath: keyPath, context: &observerContext)
        }
        
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemFailedToPlayToEndTime, object: nil)
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemNewAccessLogEntry, object: nil)
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemNewErrorLogEntry, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(kCMTimebaseNotification_EffectiveRateChanged as String), object: nil)
    }
    
    func onAccessLogEntryNotification(notification: Notification) {
        if let item = notification.object as? AVPlayerItem, let accessLog = item.accessLog(), let lastEvent = accessLog.events.last {
            if #available(iOS 10.0, *) {
                PKLog.debug("event log:\n event log: averageAudioBitrate - \(lastEvent.averageAudioBitrate)\n event log: averageVideoBitrate - \(lastEvent.averageVideoBitrate)\n event log: indicatedAverageBitrate - \(lastEvent.indicatedAverageBitrate)\n event log: indicatedBitrate - \(lastEvent.indicatedBitrate)\n event log: observedBitrate - \(lastEvent.observedBitrate)\n event log: observedMaxBitrate - \(lastEvent.observedMaxBitrate)\n event log: observedMinBitrate - \(lastEvent.observedMinBitrate)\n event log: switchBitrate - \(lastEvent.switchBitrate)")
            }
            
            if lastEvent.indicatedBitrate != self.lastBitrate {
                self.lastBitrate = lastEvent.indicatedBitrate
                PKLog.trace("currentBitrate:: \(self.lastBitrate)")
                self.post(event: PlayerEvent.PlaybackParamsUpdated(currentBitrate: self.lastBitrate))
            }
        }
    }
    
    func onErrorLogEntryNotification(notification: Notification) {
        guard let playerItem = notification.object as? AVPlayerItem, let errorLog = playerItem.errorLog(), let lastEvent = errorLog.events.last else { return }
        PKLog.warning("error description: \(String(describing: lastEvent.errorComment)), error domain: \(lastEvent.errorDomain), error code: \(lastEvent.errorStatusCode)")
        self.post(event: PlayerEvent.ErrorLog(error: PlayerErrorLog(errorLogEvent: lastEvent)))
    }
    
    public func playerFailed(notification: NSNotification) {
        let newState = PlayerState.error
        self.postStateChange(newState: newState, oldState: self.currentState)
        self.currentState = newState
        
        if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? NSError {
            self.post(event: PlayerEvent.Error(error: PlayerError.failedToPlayToEndTime(rootError: error)))
        } else {
            self.post(event: PlayerEvent.Error())
        }
    }
    
    public func playerPlayedToEnd(notification: NSNotification) {
        let newState = PlayerState.idle
        self.postStateChange(newState: newState, oldState: self.currentState)
        self.currentState = newState
        // In iOS 9 and below rate is 1.0 even when playback is finished.
        // To make sure rate will be 0.0 (paused) when played to end we call pause manually.
        self.pause()
        // pause should be called before ended to make sure our rate will be 0.0 when ended event will be observed.
        self.post(event: PlayerEvent.Ended())
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        PKLog.debug("observeValue:: onEvent/onState")
        
        guard context == &observerContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        guard let keyPath = keyPath else {
            return
        }
        
        PKLog.debug("keyPath:: \(keyPath)")
        
        switch keyPath {
        case #keyPath(currentItem.playbackLikelyToKeepUp):
            self.handleLikelyToKeepUp()
        case #keyPath(currentItem.playbackBufferEmpty):
            self.handleBufferEmptyChange()
        case #keyPath(currentItem.duration):
            if let currentItem = self.currentItem {
                self.post(event: PlayerEvent.DurationChanged(duration: CMTimeGetSeconds(currentItem.duration)))
            }
        case #keyPath(rate):
            self.handleRate()
        case #keyPath(currentItem.status):
            self.handleStatusChange()
        case #keyPath(currentItem):
            self.handleItemChange()
        case #keyPath(currentItem.timedMetadata):
            self.handleTimedMedia()
        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    private func handleLikelyToKeepUp() {
        if self.currentItem != nil {
            let newState = PlayerState.ready
            self.postStateChange(newState: newState, oldState: self.currentState)
            self.currentState = newState
        }
    }
    
    private func handleBufferEmptyChange() {
        if self.currentItem != nil {
            let newState = PlayerState.buffering
            self.postStateChange(newState: newState, oldState: self.currentState)
            self.currentState = newState
        }
    }
    
    /// Handles changes in player timebase
    func timebaseChanged(notification: Notification) {
        // for some reason timebase rate changed is received on a background thread.
        // in order to check self.rate we must make sure we are on the main thread.
        DispatchQueue.main.sync {
            guard let timebase = self.currentItem?.timebase else { return }
            PKLog.debug("timebase changed, current timebase: \(String(describing: timebase))")
            let timebaseRate = CMTimebaseGetRate(timebase)
            if timebaseRate > 0 {
                self.post(event: PlayerEvent.Playing())
            } else if timebaseRate == 0 && self.rate == 0 {
                self.post(event: PlayerEvent.Pause())
            }
        }
    }
    
    /// Handles changes in player rate
    private func handleRate() {
        PKLog.debug("player rate was changed, now: \(self.rate)")
    }
    
    private func handleStatusChange() {
        if currentItem?.status == .readyToPlay {
            let newState = PlayerState.ready
            self.post(event: PlayerEvent.LoadedMetadata())
            
            if self.startPosition > 0 {
                self.currentPosition = self.startPosition
                self.startPosition = 0
            }
            
            self.tracksManager.handleTracks(item: self.currentItem, block: { (tracks: PKTracks) in
                self.post(event: PlayerEvent.TracksAvailable(tracks: tracks))
            })
            
            self.postStateChange(newState: newState, oldState: self.currentState)
            self.currentState = newState
            
            self.post(event: PlayerEvent.CanPlay())
        } else if currentItem?.status == .failed {
            let newState = PlayerState.error
            self.postStateChange(newState: newState, oldState: self.currentState)
            self.currentState = newState
        }
    }
    
    private func handleItemChange() {
        let newState = PlayerState.idle
        self.postStateChange(newState: newState, oldState: self.currentState)
        self.currentState = newState
    }
    
    private func handleTimedMedia() {
        guard let currentItem = self.currentItem else { return }
        guard let metadata = currentItem.timedMetadata else { return }
        self.post(event: PlayerEvent.TimedMetadata(metadata: metadata))
    }
}
