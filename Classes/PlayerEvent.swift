//
//  PlayerEvent.swift
//  Pods
//
//  Created by Eliza Sapir on 14/11/2016.
//
//
import Foundation
import AVFoundation

@objc public class PKPlaybackInfo: NSObject {
    let bitrate: Double
    let indicatedBitrate: Double
    let observedBitrate: Double
    
    init(bitrate: Double, indicatedBitrate: Double, observedBitrate: Double) {
        self.bitrate = bitrate
        self.indicatedBitrate = indicatedBitrate
        self.observedBitrate = observedBitrate
    }
    
    convenience init(logEvent: AVPlayerItemAccessLogEvent) {
        let bitrate: Double
        if logEvent.segmentsDownloadedDuration > 0 {
            // bitrate is equal to:
            // (amount of bytes transfered) * 8 (bits in byte) / (amount of time took to download the transfered bytes)
            bitrate = Double(logEvent.numberOfBytesTransferred * 8) / logEvent.segmentsDownloadedDuration
        } else {
            bitrate = logEvent.indicatedBitrate
        }
        let indicatedBitrate = logEvent.indicatedBitrate
        let observedBitrate = logEvent.observedBitrate
        self.init(bitrate: bitrate, indicatedBitrate: indicatedBitrate, observedBitrate: observedBitrate)
    }
}

/// PlayerEvent is a class used to reflect player events.
@objc public class PlayerEvent: PKEvent {
    
    // All events EXCLUDING error. Assuming error events are treated differently.
    @objc public static let allEventTypes: [PlayerEvent.Type] = [
        canPlay, durationChanged, ended, loadedMetadata,
        play, pause, playing, seeking, seeked, stateChanged,
        tracksAvailable, playbackInfo, error
    ]
    
    // MARK: - Player Events Static Reference
    
    /// Sent when enough data is available that the media can be played, at least for a couple of frames.
    @objc public static let canPlay: PlayerEvent.Type = CanPlay.self
    /// The metadata has loaded or changed, indicating a change in duration of the media. This is sent, for example, when the media has loaded enough that the duration is known.
    @objc public static let durationChanged: PlayerEvent.Type = DurationChanged.self
    /// Sent when playback stopped.
    @objc public static let stopped: PlayerEvent.Type = Stopped.self
    /// Sent when playback completes.
    @objc public static let ended: PlayerEvent.Type = Ended.self
    /// The media's metadata has finished loading; all attributes now contain as much useful information as they're going to.
    @objc public static let loadedMetadata: PlayerEvent.Type = LoadedMetadata.self
    /// Sent when playback of the media starts after having been paused; that is, when playback is resumed after a prior pause event.
    @objc public static let play: PlayerEvent.Type = Play.self
    /// Sent when playback is paused.
    @objc public static let pause: PlayerEvent.Type = Pause.self
    /// Sent when the media begins to play (either for the first time, after having been paused, or after ending and then restarting).
    @objc public static let playing: PlayerEvent.Type = Playing.self
    /// Sent when a seek operation begins.
    @objc public static let seeking: PlayerEvent.Type = Seeking.self
    /// Sent when a seek operation completes.
    @objc public static let seeked: PlayerEvent.Type = Seeked.self
    /// Sent when tracks available.
    @objc public static let tracksAvailable: PlayerEvent.Type = TracksAvailable.self
    /// Sent when Playback Params Updated.
    @objc public static let playbackInfo: PlayerEvent.Type = PlaybackInfo.self
    /// Sent when player state is changed.
    @objc public static let stateChanged: PlayerEvent.Type = StateChanged.self
    /// Sent when timed metadata is available.
    @objc public static let timedMetadata: PlayerEvent.Type = TimedMetadata.self
    
    /// Sent when an error occurs.
    @objc public static let error: PlayerEvent.Type = Error.self
    /// Sent when an plugin error occurs.
    @objc public static let pluginError: PlayerEvent.Type = PluginError.self
    /// Sent when an error log event received from player.
    @objc public static let errorLog: PlayerEvent.Type = ErrorLog.self
    
    // MARK: - Player Basic Events

    class CanPlay: PlayerEvent {}
    class DurationChanged: PlayerEvent {
        convenience init(duration: TimeInterval) {
            self.init([EventDataKeys.duration: NSNumber(value: duration)])
        }
    }
    
    class Stopped: PlayerEvent {}
    class Ended: PlayerEvent {}
    class LoadedMetadata: PlayerEvent {}
    class Play: PlayerEvent {}
    class Pause: PlayerEvent {}
    class Playing: PlayerEvent {}
    class Seeking: PlayerEvent {}
    class Seeked: PlayerEvent {}
    
    class MediaPrepared: PlayerEvent {
        convenience init(contentURL: URL) {
            self.init([EventDataKeys.contentURL: contentURL])
        }
    }
    
    class Error: PlayerEvent {
        convenience init(nsError: NSError) {
            self.init([EventDataKeys.error: nsError])
        }
        
        convenience init(error: PKError) {
            self.init([EventDataKeys.error: error.asNSError])
        }
    }
    
    class PluginError: PlayerEvent {
        convenience init(nsError: NSError) {
            self.init([EventDataKeys.error: nsError])
        }
        
        convenience init(error: PKError) {
            self.init([EventDataKeys.error: error.asNSError])
        }
    }
    
    class ErrorLog: PlayerEvent {
        convenience init(nsError: NSError) {
            self.init([EventDataKeys.error: nsError])
        }
        
        convenience init(error: PKError) {
            self.init([EventDataKeys.error: error.asNSError])
        }
    }
    
    class TimedMetadata: PlayerEvent {
        convenience init(metadata: [AVMetadataItem]) {
            self.init([EventDataKeys.metadata: metadata])
        }
    }
    
    // MARK: - Player Tracks Events
    
    class TracksAvailable: PlayerEvent {
        convenience init(tracks: PKTracks) {
            self.init([EventDataKeys.tracks : tracks])
        }
    }
    
    class PlaybackInfo: PlayerEvent {
        convenience init(playbackInfo: PKPlaybackInfo) {
            self.init([EventDataKeys.playbackInfo: playbackInfo])
        }
    }
    
    // MARK: - Player State Events

    class StateChanged: PlayerEvent {
        convenience init(newState: PlayerState, oldState: PlayerState) {
            self.init([EventDataKeys.newState : newState as AnyObject,
                       EventDataKeys.oldState : oldState as AnyObject])
        }
    }
}

@objc public class AdEvent: PKEvent {
    @objc public static let allEventTypes: [AdEvent.Type] = [
        adBreakReady, allAdsCompleted, adComplete, adClicked, adCuePointsUpdate, adFirstQuartile, adLoaded, adLog, adMidpoint, adPaused, adResumed, adSkipped, adStarted, adTapped, adThirdQuartile, adDidProgressToTime, adDidRequestContentPause, adDidRequestContentResume, adWebOpenerWillOpenExternalBrowser, adWebOpenerWillOpenInAppBrowser, adWebOpenerDidOpenInAppBrowser, adWebOpenerWillCloseInAppBrowser, adWebOpenerDidCloseInAppBrowser, requestTimedOut
    ]
    
    @objc public static let adBreakReady: AdEvent.Type = AdBreakReady.self
    @objc public static let allAdsCompleted: AdEvent.Type = AllAdsCompleted.self
    @objc public static let adComplete: AdEvent.Type = AdComplete.self
    @objc public static let adClicked: AdEvent.Type = AdClicked.self
    @objc public static let adFirstQuartile: AdEvent.Type = AdFirstQuartile.self
    @objc public static let adLoaded: AdEvent.Type = AdLoaded.self
    @objc public static let adLog: AdEvent.Type = AdLog.self
    @objc public static let adMidpoint: AdEvent.Type = AdMidpoint.self
    @objc public static let adPaused: AdEvent.Type = AdPaused.self
    @objc public static let adResumed: AdEvent.Type = AdResumed.self
    @objc public static let adSkipped: AdEvent.Type = AdSkipped.self
    @objc public static let adStarted: AdEvent.Type = AdStarted.self
    @objc public static let adTapped: AdEvent.Type = AdTapped.self
    @objc public static let adThirdQuartile: AdEvent.Type = AdThirdQuartile.self
    @objc public static let adDidProgressToTime: AdEvent.Type = AdDidProgressToTime.self
    /// Ad requested the content to pause (before ad starts playing)
    @objc public static let adDidRequestContentPause: AdEvent.Type = AdDidRequestContentPause.self
    /// Ad requested content resume (when finished playing ads or when error occurs and playback needs to continue)
    @objc public static let adDidRequestContentResume: AdEvent.Type = AdDidRequestContentResume.self
    @objc public static let webOpenerEvent: AdEvent.Type = WebOpenerEvent.self
    @objc public static let adWebOpenerWillOpenExternalBrowser: AdEvent.Type = AdWebOpenerWillOpenExternalBrowser.self
    @objc public static let adWebOpenerWillOpenInAppBrowser: AdEvent.Type = AdWebOpenerWillOpenInAppBrowser.self
    @objc public static let adWebOpenerDidOpenInAppBrowser: AdEvent.Type = AdWebOpenerDidOpenInAppBrowser.self
    @objc public static let adWebOpenerWillCloseInAppBrowser: AdEvent.Type = AdWebOpenerWillCloseInAppBrowser.self
    @objc public static let adWebOpenerDidCloseInAppBrowser: AdEvent.Type = AdWebOpenerDidCloseInAppBrowser.self
    @objc public static let adCuePointsUpdate: AdEvent.Type = AdCuePointsUpdate.self
    /// Sent when an ad started buffering
    @objc public static let adStartedBuffering: AdEvent.Type = AdStartedBuffering.self
    /// Sent when ad finished buffering and ready for playback
    @objc public static let adPlaybackReady: AdEvent.Type = AdPlaybackReady.self
    /// Sent when the ads request timed out.
    @objc public static let requestTimedOut: AdEvent.Type = RequestTimedOut.self
    /// delivered when ads request was sent.
    @objc public static let adsRequested: AdEvent.Type = AdsRequested.self
    /// Sent when an error occurs.
    @objc public static let error: AdEvent.Type = Error.self
    
    class AdStarted: AdEvent {
        convenience init(adInfo: PKAdInfo) {
            self.init([AdEventDataKeys.adInfo: adInfo])
        }
    }
    
    class AdLoaded: AdEvent {
        convenience init(adInfo: PKAdInfo) {
            self.init([AdEventDataKeys.adInfo: adInfo])
        }
    }
    
    class AdBreakReady: AdEvent {}
    class AllAdsCompleted: AdEvent {}
    class AdComplete: AdEvent {}
    class AdClicked: AdEvent {}
    class AdFirstQuartile: AdEvent {}
    class AdLog: AdEvent {}
    class AdMidpoint: AdEvent {}
    class AdPaused: AdEvent {}
    class AdResumed: AdEvent {}
    class AdSkipped: AdEvent {}
    class AdTapped: AdEvent {}
    class AdThirdQuartile: AdEvent {}
    
    class AdStartedBuffering: AdEvent {}
    class AdPlaybackReady: AdEvent {}
    
    // `AdCuePointsUpdate` event is received when ad cue points were updated. only sent when there is more then 0.
    class AdCuePointsUpdate: AdEvent {
        convenience init(adCuePoints: PKAdCuePoints) {
            self.init([AdEventDataKeys.adCuePoints: adCuePoints])
        }
    }
    
    class Error: AdEvent {
        convenience init(nsError: NSError) {
            self.init([AdEventDataKeys.error: nsError])
        }
    }
    
    class AdDidProgressToTime: AdEvent {
        convenience init(mediaTime: TimeInterval, totalTime: TimeInterval) {
            self.init([AdEventDataKeys.mediaTime: NSNumber(value: mediaTime),
                       AdEventDataKeys.totalTime: NSNumber(value: totalTime)])
        }
    }
    
    class AdDidRequestContentPause: AdEvent {}
    class AdDidRequestContentResume: AdEvent {}
    
    /// Sent when the ads request timed out.
    class RequestTimedOut: AdEvent {}
    /// delivered when ads request was sent.
    class AdsRequested: AdEvent {
        convenience init(adTagUrl: String) {
            self.init([AdEventDataKeys.adTagUrl: adTagUrl])
        }
    }
    
    class WebOpenerEvent: AdEvent {
        convenience init(webOpener: NSObject!) {
            self.init([AdEventDataKeys.webOpener: webOpener])
        }
    }
    
    class AdWebOpenerWillOpenExternalBrowser: WebOpenerEvent {}
    class AdWebOpenerWillOpenInAppBrowser: WebOpenerEvent {}
    class AdWebOpenerDidOpenInAppBrowser: WebOpenerEvent {}
    class AdWebOpenerWillCloseInAppBrowser: WebOpenerEvent {}
    class AdWebOpenerDidCloseInAppBrowser: WebOpenerEvent {}
}

/************************************************************/
// MARK: - PKEvent Data Accessors Extension
/************************************************************/

extension PKEvent {
    // MARK: - Ad Data Keys
    struct AdEventDataKeys {
        static let mediaTime = "mediaTime"
        static let totalTime = "totalTime"
        static let webOpener = "webOpener"
        static let error = "error"
        static let adCuePoints = "adCuePoints"
        static let adInfo = "adInfo"
        static let adTagUrl = "adTagUrl"
    }
    
    // MARK: Ad Data Accessors
    
    /// MediaTime, PKEvent Ad Data Accessor
    @objc public var adMediaTime: NSNumber? {
        return self.data?[AdEventDataKeys.mediaTime] as? NSNumber
    }
    
    /// TotalTime, PKEvent Ad Data Accessor
    @objc public var adTotalTime: NSNumber? {
        return self.data?[AdEventDataKeys.totalTime] as? NSNumber
    }
    
    /// WebOpener, PKEvent Ad Data Accessor
    @objc public var adWebOpener: NSObject? {
        return self.data?[AdEventDataKeys.webOpener] as? NSObject
    }
    
    /// Associated error from error event, PKEvent Ad Data Accessor
    @objc public var adError: NSError? {
        return self.data?[AdEventDataKeys.error] as? NSError
    }
    
    /// Ad cue points, PKEvent Ad Data Accessor
    @objc public var adCuePoints: PKAdCuePoints? {
        return self.data?[AdEventDataKeys.adCuePoints] as? PKAdCuePoints
    }
    
    /// TotalTime, PKEvent Ad Data Accessor
    @objc public var adTagUrl: String? {
        return self.data?[AdEventDataKeys.adTagUrl] as? String
    }
}
