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
import CoreMedia

extension AVPlayerEngine {
    
    // An array of key paths for the properties we want to observe.
    private var observedKeyPaths: [String] {
        return [
            #keyPath(rate),
            #keyPath(status),
            #keyPath(currentItem),
            #keyPath(currentItem.status),
            #keyPath(currentItem.isPlaybackLikelyToKeepUp),
            #keyPath(currentItem.isPlaybackBufferEmpty),
            #keyPath(currentItem.isPlaybackBufferFull),
            #keyPath(currentItem.loadedTimeRanges),
            #keyPath(currentItem.timedMetadata),
            #keyPath(currentItem.duration)
        ]
    }
    
    // - Observers
    func addObservers() {
        PKLog.verbose("addObservers")
        
        self.isObserved = true
        // Register observers for the properties we want to display.
        for keyPath in observedKeyPaths {
            addObserver(self, forKeyPath: keyPath, options: [.new, .initial], context: &AVPlayerEngine.observerContext)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.didFailToPlayToEndTime(_:)), name: .AVPlayerItemFailedToPlayToEndTime, object: self.currentItem)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didPlayToEndTime(_:)), name: .AVPlayerItemDidPlayToEndTime, object: self.currentItem)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onAccessLogEntryNotification), name: .AVPlayerItemNewAccessLogEntry, object: self.currentItem)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onErrorLogEntryNotification), name: .AVPlayerItemNewErrorLogEntry, object: self.currentItem)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onPlaybackStalledNotification), name: .AVPlayerItemPlaybackStalled, object: self.currentItem)
        NotificationCenter.default.addObserver(self, selector: #selector(self.timebaseChanged), name: Notification.Name(kCMTimebaseNotification_EffectiveRateChanged as String), object: nil)
    }
    
    func removeObservers() {
        if !self.isObserved {
            return
        }
        
        PKLog.verbose("removeObservers")
        
        // Un-register observers
        for keyPath in observedKeyPaths {
            removeObserver(self, forKeyPath: keyPath, context: &AVPlayerEngine.observerContext)
        }
        
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemFailedToPlayToEndTime, object: self.currentItem)
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: self.currentItem)
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemNewAccessLogEntry, object: self.currentItem)
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemNewErrorLogEntry, object: self.currentItem)
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemPlaybackStalled, object: self.currentItem)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(kCMTimebaseNotification_EffectiveRateChanged as String), object: nil)
    }
    
    @objc func onAccessLogEntryNotification(notification: Notification) {
        if let playerItem = notification.object as? AVPlayerItem, let accessLog = playerItem.accessLog(),
            let lastEvent = accessLog.events.last, playerItem === self.currentItem {
            if #available(iOS 10.0, tvOS 10.0, *) {
                PKLog.debug("event log:\n event log: averageAudioBitrate - \(lastEvent.averageAudioBitrate)\n event log: averageVideoBitrate - \(lastEvent.averageVideoBitrate)\n event log: indicatedAverageBitrate - \(lastEvent.indicatedAverageBitrate)\n event log: indicatedBitrate - \(lastEvent.indicatedBitrate)\n event log: observedBitrate - \(lastEvent.observedBitrate)\n event log: observedMaxBitrate - \(lastEvent.observedMaxBitrate)\n event log: observedMinBitrate - \(lastEvent.observedMinBitrate)\n event log: switchBitrate - \(lastEvent.switchBitrate)\n event log: numberOfBytesTransferred - \(lastEvent.numberOfBytesTransferred)\n event log: numberOfStalls - \(lastEvent.numberOfStalls)\n event log: URI - \(String(describing: lastEvent.uri))\n event log: startupTime - \(lastEvent.startupTime)")
            }
            
            self.post(event: PlayerEvent.PlaybackInfo(playbackInfo: PKPlaybackInfo(logEvent: lastEvent)))
            if self.lastIndicatedBitrate != lastEvent.indicatedBitrate {
                self.lastIndicatedBitrate = lastEvent.indicatedBitrate
                self.post(event: PlayerEvent.VideoTrackChanged(bitrate: lastEvent.indicatedBitrate))
            }
        }
    }
    
    @objc func onErrorLogEntryNotification(notification: Notification) {
        guard let playerItem = notification.object as? AVPlayerItem,
            let errorLog = playerItem.errorLog(),
            let lastEvent = errorLog.events.last,
            playerItem === self.currentItem else { return }
        PKLog.warning("error description: \(String(describing: lastEvent.errorComment)), error domain: \(lastEvent.errorDomain), error code: \(lastEvent.errorStatusCode)")
        self.post(event: PlayerEvent.ErrorLog(error: PlayerErrorLog(errorLogEvent: lastEvent)))
    }
    
    @objc func onPlaybackStalledNotification(notification: Notification) {
        // post notification only for current player item.
        guard let notificationObject = notification.object as? AVPlayerItem, notificationObject === self.currentItem else { return }
        
        self.post(event: PlayerEvent.PlaybackStalled())
    }
    
    @objc func didFailToPlayToEndTime(_ notification: NSNotification) {
        // post notification only for current player item.
        guard let notificationObject = notification.object as? AVPlayerItem, notificationObject === self.currentItem else { return }
        let newState = PlayerState.error
        self.postStateChange(newState: newState, oldState: self.currentState)
        self.currentState = newState
        
        if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? NSError {
            self.post(event: PlayerEvent.Error(error: PlayerError.playerItemFailed(rootError: error)))
        } else {
            self.post(event: PlayerEvent.Error())
        }
    }
    
    @objc func didPlayToEndTime(_ notification: NSNotification) {
        // post notification only for current player item.
        guard let notificationObject = notification.object as? AVPlayerItem, notificationObject === self.currentItem else { return }
        let newState = PlayerState.ended
        self.postStateChange(newState: newState, oldState: self.currentState)
        self.currentState = newState
        // In iOS 9 and below rate is 1.0 even when playback is finished.
        // To make sure rate will be 0.0 (paused) when played to end we call pause manually.
        self.pause()
        // pause should be called before ended to make sure our rate will be 0.0 when ended event will be observed.
        self.post(event: PlayerEvent.Ended())
    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        PKLog.verbose("observeValue:: onEvent/onState")
        
        guard context == &AVPlayerEngine.observerContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        guard let keyPath = keyPath else {
            return
        }
        
        PKLog.verbose("keyPath:: \(keyPath)")
        
        switch keyPath {
        case #keyPath(currentItem.isPlaybackLikelyToKeepUp):
            guard let isPlaybackLikelyToKeepUp = currentItem?.isPlaybackLikelyToKeepUp else { return }
            if (isPlaybackLikelyToKeepUp) {
                self.handleLikelyToKeepUp()
            }
        case #keyPath(currentItem.isPlaybackBufferEmpty):
            guard let isPlaybackBufferEmpty = currentItem?.isPlaybackBufferEmpty else { return }
            if (isPlaybackBufferEmpty) {
                self.handleBufferEmptyChange()
            }
        case #keyPath(currentItem.isPlaybackBufferFull):
            guard let isPlaybackBufferFull = currentItem?.isPlaybackBufferFull else { return }
            if (isPlaybackBufferFull) {
                PKLog.debug("Buffer Full")
            }
        case #keyPath(currentItem.loadedTimeRanges):
            guard let loadedTimeRanges = self.currentItem?.loadedTimeRanges else { return }
            // convert values to PKTimeRange
            let timeRanges = loadedTimeRanges.map { PKTimeRange(timeRange: $0.timeRangeValue) }
            self.post(event: PlayerEvent.LoadedTimeRanges(timeRanges: timeRanges))
        case #keyPath(rate):
            self.handleRate()
        case #keyPath(status):
            guard let statusChange = change?[.newKey] as? NSNumber, let newPlayerStatus = AVPlayer.Status(rawValue: statusChange.intValue) else {
                PKLog.error("unknown player status")
                return
            }
            self.handle(status: newPlayerStatus)
        case #keyPath(currentItem):
            self.handleItemChange()
        case #keyPath(currentItem.status):
            guard let statusChange = change?[.newKey] as? NSNumber, let newPlayerItemStatus = AVPlayerItem.Status(rawValue: statusChange.intValue) else {
                PKLog.error("unknown player item status")
                return
            }
            self.handle(playerItemStatus: newPlayerItemStatus)
        case #keyPath(currentItem.timedMetadata):
            self.handleTimedMedia()
        case #keyPath(currentItem.duration):
            self.handleDurationChanged()
        default: super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
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
    @objc func timebaseChanged(notification: Notification) {
        // For some reason timebase rate changed is received on a background thread.
        // in order to check self.rate we must make sure we are on the main thread.
        DispatchQueue.main.async {
            guard let timebase = self.currentItem?.timebase else { return }
            PKLog.verbose("timebase changed, current timebase: \(String(describing: timebase))")
            let timebaseRate = CMTimebaseGetRate(timebase)
            if timebaseRate > 0 && self.lastTimebaseRate != timebaseRate {
                self.post(event: PlayerEvent.Playing())
            } else if timebaseRate == 0 && self.rate == 0 && self.lastTimebaseRate != timebaseRate {
                self.post(event: PlayerEvent.Pause())
            }
            // Make sure to save the last value so we could only post events only when currentTimebase != lastTimebase
            self.lastTimebaseRate = timebaseRate
        }
    }
    
    /// Handles changes in player rate
    private func handleRate() {
        PKLog.debug("player rate was changed, now: \(self.rate)")
        // When setting automaticallyWaitsToMinimizeStalling and shouldPlayImmediately, the player may be stalled and the rate will be changed to 0, player paused, by the AVPlayer. Therefor we are sending a paused event.
        if self.rate == 0, self.currentState == .buffering || self.currentState == .ready {
            self.post(event: PlayerEvent.Pause())
        }
    }
    
    private func handle(status: AVPlayer.Status) {
        switch status {
        case .readyToPlay:
            PKLog.debug("player is ready to play player items")
            // Try to set the start position before the player item is ready, to avoid a glitch on VOD
            if self.duration != 0 {
                PKLog.debug("duration in seconds: \(duration)")
                self.currentPosition = self.startPosition
            }
        case .failed:
            PKLog.error("player failed you must recreate the player instance")
            if let error = (self.error as NSError?) {
                self.post(event: PlayerEvent.Error(error: PlayerError.failed(rootError: error)))
            }
        case .unknown:
            break
        @unknown default:
            break
        }
    }
    
    private func handle(playerItemStatus status: AVPlayerItem.Status) {
        switch status {
        case .readyToPlay:
            let newState = PlayerState.ready
            
            self.postStateChange(newState: newState, oldState: self.currentState)
            self.currentState = newState
            
            if self.isFirstReady {
                self.isFirstReady = false
                // handle tracks, send event and handle selection mode.
                
                self.tracksManager.handleTracks(item: self.currentItem,
                                                cea608CaptionsEnabled: self.asset?.playerSettings.cea608CaptionsEnabled ?? false,
                                                block: { (tracks: PKTracks) in
                    self.handleTracksSelection(tracks)
                    self.post(event: PlayerEvent.TracksAvailable(tracks: tracks))
                })
                // When player item is readyToPlay for the first time it is safe to assume we have a valid duration for VOD.
                if self.duration != 0 {
                    PKLog.debug("duration in seconds: \(duration)")
                    self.currentPosition = self.startPosition
                }
                self.post(event: PlayerEvent.LoadedMetadata())
                self.post(event: PlayerEvent.CanPlay())
            }
        case .failed:
            let newState = PlayerState.error
            self.postStateChange(newState: newState, oldState: self.currentState)
            self.currentState = newState
            if let error = currentItem?.error as NSError? {
                self.post(event: PlayerEvent.Error(error: PlayerError.playerItemFailed(rootError: error)))
            }
        case .unknown:
            break
        @unknown default:
            break
        }
    }
    
    private func handleItemChange() {
        let newState = PlayerState.idle
        self.postStateChange(newState: newState, oldState: self.currentState)
        self.currentState = newState
        
        // Update new current item with the text track styling which was set.
        if let textTrackStyling = self.asset?.playerSettings.textTrackStyling {
            self.updateTextTrackStyling(textTrackStyling)
        }
    }
    
    private func handleTimedMedia() {
        guard let currentItem = self.currentItem else { return }
        guard let metadata = currentItem.timedMetadata else { return }
        self.post(event: PlayerEvent.TimedMetadata(metadata: metadata))
    }
    
    private func handleTracksSelection(_ tracks: PKTracks) {
        
        func checkLanguageCode(current currentLanguageCode: String?, against languageCodeToCompare: String?) -> Bool {
            if let current = currentLanguageCode, let againstCode = languageCodeToCompare {
                let currentCanonicalLanguageIdentifier = Locale.canonicalLanguageIdentifier(from: current)
                let againstCanonicalLanguageIdentifier = Locale.canonicalLanguageIdentifier(from: againstCode)
                return current == againstCode || current == againstCanonicalLanguageIdentifier || currentCanonicalLanguageIdentifier == againstCode
            }
            return false
        }
        
        func handleAutoMode(for tracks: [Track]?) {
            guard let languageCode = Locale.current.languageCode else { return }
            guard let track = tracks?.first(where: { (track) -> Bool in
                if let trackLanguageCode = track.language {
                    return checkLanguageCode(current: languageCode, against: trackLanguageCode)
                }
                return false
            }) else { return }
            self.selectTrack(trackId: track.id)
        }
        
        func handleSelectionMode(for tracks: [Track]?, language: String?) {
            guard let track = tracks?.first(where: { checkLanguageCode(current: language, against: $0.language) }) else { return }
            self.selectTrack(trackId: track.id)
        }
    
        guard let trackSelection = self.asset?.playerSettings.trackSelection else { return }
        // handle text selection mode, default is to turn subtitles off.
        switch trackSelection.textSelectionMode {
        case .off:
            guard let track = tracks.textTracks?.first(where: { $0.title == TracksManager.textOffDisplay && $0.language == nil }) else { break }
            self.selectTrack(trackId: track.id)
        case .auto:
            handleAutoMode(for: tracks.textTracks)
        case .selection:
            handleSelectionMode(for: tracks.textTracks, language: trackSelection.textSelectionLanguage)
        }
        // handle audio selection mode, default is to let AVPlayer decide.
        switch trackSelection.audioSelectionMode {
        case .off, .auto:
            handleAutoMode(for: tracks.audioTracks)
        case .selection:
            handleSelectionMode(for: tracks.audioTracks, language: trackSelection.audioSelectionLanguage)
        }
    }
    
    func handleDurationChanged() {
        if let duration = self.currentItem?.duration, !CMTIME_IS_INDEFINITE(duration) {
            PKLog.debug("Duration in seconds: \(CMTimeGetSeconds(duration))")
            internalDuration = CMTimeGetSeconds(duration)
        }
    }
}
