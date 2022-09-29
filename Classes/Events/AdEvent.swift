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
        streamLoaded, streamStarted, adBreakReady, adBreakStarted, adBreakEnded, adPeriodStarted, adPeriodEnded, allAdsCompleted, adComplete, adClicked,
        adFirstQuartile, adLoaded, adLog, adMidpoint, adPaused, adResumed, adSkipped, adStarted, adTapped, adThirdQuartile,
        adDidProgressToTime, adDidRequestContentPause, adDidRequestContentResume, webOpenerEvent, adWebOpenerWillOpenExternalBrowser,
        adWebOpenerWillOpenInAppBrowser, adWebOpenerDidOpenInAppBrowser, adWebOpenerWillCloseInAppBrowser, adWebOpenerDidCloseInAppBrowser,
        adCuePointsUpdate, adStartedBuffering, adPlaybackReady, requestTimedOut, adsRequested, error
    ]
    
    @objc public static let streamLoaded: AdEvent.Type = StreamLoaded.self // DAI
    @objc public static let streamStarted: AdEvent.Type = StreamStarted.self // DAI
    @objc public static let adBreakReady: AdEvent.Type = AdBreakReady.self
    @objc public static let adBreakStarted: AdEvent.Type = AdBreakStarted.self // DAI
    @objc public static let adBreakEnded: AdEvent.Type = AdBreakEnded.self // DAI
    @objc public static let adPeriodStarted: AdEvent.Type = AdPeriodStarted.self // DAI
    @objc public static let adPeriodEnded: AdEvent.Type = AdPeriodEnded.self // DAI
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
    
    /************************************************************/
    // MARK: - Events
    /************************************************************/
    
    public class StreamLoaded: AdEvent {}
    public class StreamStarted: AdEvent {}
    
    public class AdStarted: AdEvent {
        public convenience init(adInfo: PKAdInfo) {
            self.init([AdEventDataKeys.adInfo: adInfo])
        }
    }
    
    public class AdLoaded: AdEvent {
        public convenience init(adInfo: PKAdInfo) {
            self.init([AdEventDataKeys.adInfo: adInfo])
        }
    }
    
    public class AdBreakReady: AdEvent {}
    public class AdBreakStarted: AdEvent {} // DAI
    public class AdBreakEnded: AdEvent {} // DAI
    public class AdPeriodStarted: AdEvent {} // DAI
    public class AdPeriodEnded: AdEvent {} // DAI
    public class AllAdsCompleted: AdEvent {}
    public class AdComplete: AdEvent {}
    public class AdClicked: AdEvent {
        public convenience init(clickThroughUrl: String) {
            self.init([AdEventDataKeys.clickThroughUrl: clickThroughUrl])
        }
    }
    public class AdFirstQuartile: AdEvent {}
    public class AdLog: AdEvent {}
    public class AdMidpoint: AdEvent {}
    
    public class AdPaused: AdEvent {
        public convenience init(adInfo: PKAdInfo) {
            self.init([AdEventDataKeys.adInfo: adInfo])
        }
    }
    
    public class AdResumed: AdEvent {
        public convenience init(adInfo: PKAdInfo) {
            self.init([AdEventDataKeys.adInfo: adInfo])
        }
    }
    
    public class AdSkipped: AdEvent {
        public convenience init(adInfo: PKAdInfo) {
            self.init([AdEventDataKeys.adInfo: adInfo])
        }
    }
    
    public class AdTapped: AdEvent {}
    public class AdThirdQuartile: AdEvent {}
    
    public class AdStartedBuffering: AdEvent {}
    public class AdPlaybackReady: AdEvent {}
    
    // `AdCuePointsUpdate` event is received when ad cue points were updated. only sent when there is more then 0.
    public class AdCuePointsUpdate: AdEvent {
        public convenience init(adCuePoints: PKAdCuePoints) {
            self.init([AdEventDataKeys.adCuePoints: adCuePoints])
        }
        public convenience init(adDAICuePoints: PKAdDAICuePoints) {
            self.init([AdEventDataKeys.adDAICuePoints: adDAICuePoints])
        }
    }
    
    public class Error: AdEvent {
        public convenience init(nsError: NSError) {
            self.init([AdEventDataKeys.error: nsError])
        }
    }
    
    public class AdDidProgressToTime: AdEvent {
        public convenience init(mediaTime: TimeInterval, totalTime: TimeInterval) {
            self.init([AdEventDataKeys.mediaTime: NSNumber(value: mediaTime),
                       AdEventDataKeys.totalTime: NSNumber(value: totalTime)])
        }
    }
    
    public class AdDidRequestContentPause: AdEvent {}
    public class AdDidRequestContentResume: AdEvent {}
    
    /// Sent when the ads request timed out.
    public class RequestTimedOut: AdEvent {}
    
    /// delivered when ads request was sent.
    public class AdsRequested: AdEvent {
        public convenience init(adTagUrl: String) {
            self.init([AdEventDataKeys.adTagUrl: adTagUrl])
        }
    }
    
    public class WebOpenerEvent: AdEvent {
        public convenience init(webOpener: NSObject!) {
            self.init([AdEventDataKeys.webOpener: webOpener as Any])
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
    public static let adDAICuePoints = "adDAICuePoints"
    public static let adInfo = "adInfo"
    public static let adTagUrl = "adTagUrl"
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
    
    /// Ad cue points, PKEvent Ad Data Accessor
    @objc public var adCuePoints: PKAdCuePoints? {
        return self.data?[AdEventDataKeys.adCuePoints] as? PKAdCuePoints
    }
    
    /// Ad DAI cue points, PKEvent Ad Data Accessor
    @objc public var adDAICuePoints: PKAdDAICuePoints? {
        return self.data?[AdEventDataKeys.adDAICuePoints] as? PKAdDAICuePoints
    }
    
    /// AdTagUrl, PKEvent Ad Data Accessor
    @objc public var adTagUrl: String? {
        return self.data?[AdEventDataKeys.adTagUrl] as? String
    }
    
    /// Ad info, PKEvent Ad Data Accessor
    @objc public var adInfo: PKAdInfo? {
        return self.data?[AdEventDataKeys.adInfo] as? PKAdInfo
    }
    
    /// ClickThroughUrl, PKEvent Ad Data Accessor
    @objc public var clickThroughUrl: String? {
        return self.data?[AdEventDataKeys.clickThroughUrl] as? String
    }
}
