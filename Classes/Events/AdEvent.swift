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

@objc public class AdEvent: PKEvent {
    
    /************************************************************/
    // MARK: - Events Type
    /************************************************************/
    
    @objc public static let allEventTypes: [AdEvent.Type] = [
        adBreakPending, allAdsCompleted, adEnded, adClicked, adCuePoints, adFirstQuartile, adLoaded, errorLog, adMidpoint, adPaused, adResumed, adSkipped, adStarted, adTouched, adThirdQuartile, adProgress, contentPauseRequested, contentResumeRequested, adWebOpenerWillOpenExternalBrowser, adWebOpenerWillOpenInAppBrowser, adWebOpenerDidOpenInAppBrowser, adWebOpenerWillCloseInAppBrowser, adWebOpenerDidCloseInAppBrowser, adsRequestTimedOut, adBreakStarted, adBreakEnded, error
    ] // TOOD: add adsPlaybackEnded
    
    /// An ad break is pending to be played, should pause content player at this point.
    @objc public static let adBreakPending: AdEvent.Type = AdBreakPending.self
    @objc public static let adBreakStarted: AdEvent.Type = AdBreakStarted.self
    /// An ad break has ended, should resume content at this point.
    @objc public static let adBreakEnded: AdEvent.Type = AdBreakEnded.self
    @objc public static let allAdsCompleted: AdEvent.Type = AllAdsCompleted.self
    @objc public static let adLoaded: AdEvent.Type = AdLoaded.self
    @objc public static let adStarted: AdEvent.Type = AdStarted.self
    @objc public static let adProgress: AdEvent.Type = AdProgress.self
    @objc public static let adEnded: AdEvent.Type = AdEnded.self
    @objc public static let adPaused: AdEvent.Type = AdPaused.self
    @objc public static let adResumed: AdEvent.Type = AdResumed.self
    @objc public static let adSkipped: AdEvent.Type = AdSkipped.self
    @objc public static let adTouched: AdEvent.Type = AdTouched.self
    @objc public static let adClicked: AdEvent.Type = AdClicked.self
    @objc public static let adFirstQuartile: AdEvent.Type = AdFirstQuartile.self
    @objc public static let adMidpoint: AdEvent.Type = AdMidpoint.self
    @objc public static let adThirdQuartile: AdEvent.Type = AdThirdQuartile.self
    @objc public static let adCuePoints: AdEvent.Type = AdCuePoints.self
    /// Sent when an ad started buffering
    @objc public static let adStartedBuffering: AdEvent.Type = AdStartedBuffering.self
    /// Sent when ad finished buffering and ready for playback
    @objc public static let adPlaybackReady: AdEvent.Type = AdPlaybackReady.self
    /// Sent when the ads request timed out.
    @objc public static let adsRequestTimedOut: AdEvent.Type = AdsRequestTimedOut.self
    /// delivered when ads request was sent.
    @objc public static let adsRequested: AdEvent.Type = AdsRequested.self
    
    /// Ad requested the content to pause (before ad starts playing)
    @objc public static let contentPauseRequested: AdEvent.Type = ContentPauseRequested.self
    /// Ad requested content resume (when finished playing ads or when error occurs and playback needs to continue)
    @objc public static let contentResumeRequested: AdEvent.Type = ContentResumeRequested.self
    @objc public static let webOpenerEvent: AdEvent.Type = WebOpenerEvent.self
    @objc public static let adWebOpenerWillOpenExternalBrowser: AdEvent.Type = AdWebOpenerWillOpenExternalBrowser.self
    @objc public static let adWebOpenerWillOpenInAppBrowser: AdEvent.Type = AdWebOpenerWillOpenInAppBrowser.self
    @objc public static let adWebOpenerDidOpenInAppBrowser: AdEvent.Type = AdWebOpenerDidOpenInAppBrowser.self
    @objc public static let adWebOpenerWillCloseInAppBrowser: AdEvent.Type = AdWebOpenerWillCloseInAppBrowser.self
    @objc public static let adWebOpenerDidCloseInAppBrowser: AdEvent.Type = AdWebOpenerDidCloseInAppBrowser.self
    
    /// Sent when an error occurs.
    @objc public static let error: AdEvent.Type = Error.self
    /// Sent when an error log occurs (non-fatal error)
    @objc public static let errorLog: AdEvent.Type = ErrorLog.self
    
    /************************************************************/
    // MARK: - Events
    /************************************************************/
    
    /// `AdStarted` represents an ad have started playing.
    public class AdStarted: AdEvent {
        public convenience init(adInfo: PKAdInfo) {
            self.init([AdEventDataKeys.adInfo: adInfo])
        }
    }
    
    /// `AdLoaded` represents an ad have loaded.
    public class AdLoaded: AdEvent {
        public convenience init(adInfo: PKAdInfo) {
            self.init([AdEventDataKeys.adInfo: adInfo])
        }
    }
    
    /// `AdBreakPending` represents an ad break is pending to be played.
    public class AdBreakPending: AdEvent {
        public convenience init(adBreakInfo: [PKAdBreakInfo]) {
            self.init([AdEventDataKeys.adBreakInfo: adBreakInfo])
        }
    }
    
    /// `AdBreakStarted` represents an ad break started playing (the first ad in the ad break started).
    public class AdBreakStarted: AdEvent {
        public convenience init(adBreakInfo: PKAdBreakInfo) {
            self.init([AdEventDataKeys.adBreakInfo: adBreakInfo])
        }
    }
    
    /// `AdBreakEnded` represents an ad break finished playing (the last ad in the ad break finished).
    public class AdBreakEnded: AdEvent {
        public convenience init(adBreakInfo: PKAdBreakInfo, reason: PKAdBreakEndedReason) {
            self.init([AdEventDataKeys.adBreakInfo: adBreakInfo, AdEventDataKeys.adBreakEndedReason: reason])
        }
    }
    
    /// `AllAdsCompleted` represents all ads have been played.
    public class AllAdsCompleted: AdEvent {}
    
    /// `AdEnded` represents an ad finished playing.
    public class AdEnded: AdEvent {
        public convenience init(adInfo: PKAdInfo, reason: PKAdEndedReason) {
            self.init([AdEventDataKeys.adInfo: adInfo, AdEventDataKeys.adEndedReason: reason])
        }
    }
    
    /// `AdClicked` ad click through was clicked (learn more button).
    public class AdClicked: AdEvent {
        public convenience init(clickThroughUrl: URL) {
            self.init([AdEventDataKeys.clickThroughUrl: clickThroughUrl])
        }
    }
    
    /// `AdFirstQuartile` ad arrived at first quartile.
    public class AdFirstQuartile: AdEvent {}
    
    /// `AdMidpoint` ad arrived at midpoint.
    public class AdMidpoint: AdEvent {}
    
    /// `AdThirdQuartile` ad arrived at third quartile.
    public class AdThirdQuartile: AdEvent {}
    
    /// `AdPaused` represents an ad was paused.
    public class AdPaused: AdEvent {
        public convenience init(offset: TimeInterval) {
            self.init([AdEventDataKeys.offset: NSNumber(value: offset)])
        }
    }
    
    /// `AdResumed` represents an ad was resumed.
    public class AdResumed: AdEvent {}
    
    /// `AdSkipped` represents an ad was skipped.
    public class AdSkipped: AdEvent {
        public convenience init(offset: TimeInterval) {
            self.init([AdEventDataKeys.offset: NSNumber(value: offset)])
        }
    }
    
    /// `AdTouched` represents an ad was touched outside the click through button.
    public class AdTouched: AdEvent {}
    
    /// `AdStartedBuffering` represents an ad has started buffering.
    public class AdStartedBuffering: AdEvent {}
    
    /// `AdPlaybackReady` represents an ad has buffered enough to continue playback.
    public class AdPlaybackReady: AdEvent {}
    
    // `AdCuePointsUpdate` event is received when ad cue points were updated. only sent when there is more then 0.
    public class AdCuePoints: AdEvent {
        public convenience init(adCuePoints: PKAdCuePoints) {
            self.init([AdEventDataKeys.adCuePoints: adCuePoints])
        }
    }
    
    /// `Error` represents an ad provider encoutered an error.
    public class Error: AdEvent {
        public convenience init(nsError: NSError) {
            self.init([AdEventDataKeys.error: nsError])
        }
    }
    
    /// `ErrorLog` represents an ad provider encoutered a non-fatal error.
    public class ErrorLog: AdEvent {
        public convenience init(nsError: NSError) {
            self.init([AdEventDataKeys.error: nsError])
        }
    }
    
    /// The ad timed progress events
    public class AdProgress: AdEvent {
        public convenience init(mediaTime: TimeInterval, totalTime: TimeInterval) {
            self.init([AdEventDataKeys.mediaTime: NSNumber(value: mediaTime),
                       AdEventDataKeys.totalTime: NSNumber(value: totalTime)])
        }
    }
    
    public class ContentPauseRequested: AdEvent {}
    public class ContentResumeRequested: AdEvent {}
    
    /// Sent when the ads request timed out.
    public class AdsRequestTimedOut: AdEvent {}
    
    /// delivered when ads request was sent.
    public class AdsRequested: AdEvent {
        public convenience init(adTagUrl: String) {
            self.init([AdEventDataKeys.adTagUrl: adTagUrl])
        }
    }
    
    /// `AdsAndContentEnded` sent when both ads and content has completed playing.
    /// - important: even if some ads were skipped by seeking when the content has ended 
    /// and post-roll was played (only if we had one) we send this event.
    public class AdsAndContentEnded: AdEvent {
        public convenience init(adTagUrl: String) {
            self.init([AdEventDataKeys.adTagUrl: adTagUrl])
        }
    }
    
    public class WebOpenerEvent: AdEvent {
        public convenience init(webOpener: NSObject!) {
            self.init([AdEventDataKeys.webOpener: webOpener])
        }
    }
    
    public class AdWebOpenerWillOpenExternalBrowser: WebOpenerEvent {}
    public class AdWebOpenerWillOpenInAppBrowser: WebOpenerEvent {}
    public class AdWebOpenerDidOpenInAppBrowser: WebOpenerEvent {}
    public class AdWebOpenerWillCloseInAppBrowser: WebOpenerEvent {}
    public class AdWebOpenerDidCloseInAppBrowser: WebOpenerEvent {}
}

/************************************************************/
// MARK: - PKEvent Data Accessors Extension
/************************************************************/

/// AdEvent data keys, used to access/put data in `AdEvent`.
@objc public class AdEventDataKeys: NSObject {
    public static let mediaTime = "mediaTime"
    public static let totalTime = "totalTime"
    public static let webOpener = "webOpener"
    public static let error = "error"
    public static let adCuePoints = "adCuePoints"
    public static let adInfo = "adInfo"
    public static let adEndedReason = "adEndedReason"
    public static let adBreakInfo = "adBreakInfo"
    public static let adBreakEndedReason = "adBreakEndedReason"
    public static let adTagUrl = "adTagUrl"
    public static let offset = "offset"
    public static let clickThroughUrl = "clickThroughUrl"
}

extension PKEvent {
       
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
    
    /// Ad error log PKEvent accessor
    @objc public var adErrorLog: NSError? {
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
    
    /// Ad info, PKEvent Ad Data Accessor
    @objc public var adInfo: PKAdInfo? {
        return self.data?[AdEventDataKeys.adInfo] as? PKAdInfo
    }
    
    /// Ad break info PKEvent accessor
    @objc public var adBreakInfo: PKAdBreakInfo? {
        return self.data?[AdEventDataKeys.adBreakInfo] as? PKAdBreakInfo
    }
    
    /// Ad offset PKEvent accessor
    @objc public var offset: NSNumber? {
        return self.data?[AdEventDataKeys.offset] as? NSNumber
    }
    
    /// Ad click through url PKEvent accessor
    @objc public var clickThroughUrl: URL? {
        return self.data?[AdEventDataKeys.clickThroughUrl] as? URL
    }
    
    /// Ad break ended reason PKEvent accessor
    @objc public var adBreakEndedReason: PKAdBreakEndedReason? {
        return self.data?[AdEventDataKeys.adBreakEndedReason] as? PKAdBreakEndedReason
    }
    
    /// Ad ended reason PKEvent accessor
    @objc public var adEndedReason: PKAdEndedReason? {
        return self.data?[AdEventDataKeys.adEndedReason] as? PKAdEndedReason
    }
}
