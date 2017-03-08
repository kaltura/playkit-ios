//
//  AdEvent.swift
//  Pods
//
//  Created by Gal Orlanczyk on 07/03/2017.
//
//

import Foundation

@objc public class AdEvent: PKEvent {
    @objc public static let allEventTypes: [AdEvent.Type] = [
        adBreakReady, adBreakEnded, adBreakStarted, adAllCompleted, adComplete, adClicked, adCuePointsChanged, adFirstQuartile, adLoaded, adLog, adMidpoint, adPaused, adResumed, adSkipped, adStarted, adStreamLoaded, adTapped, adThirdQuartile, adDidProgressToTime, adDidRequestPause, adDidRequestResume, adWebOpenerWillOpenExternalBrowser, adWebOpenerWillOpenInAppBrowser, adWebOpenerDidOpenInAppBrowser, adWebOpenerWillCloseInAppBrowser, adWebOpenerDidCloseInAppBrowser
    ]
    
    @objc public static let adBreakReady: AdEvent.Type = AdBreakReady.self
    @objc public static let adBreakEnded: AdEvent.Type = AdBreakEnded.self
    @objc public static let adBreakStarted: AdEvent.Type = AdBreakStarted.self
    @objc public static let adAllCompleted: AdEvent.Type = AdAllCompleted.self
    @objc public static let adComplete: AdEvent.Type = AdComplete.self
    @objc public static let adClicked: AdEvent.Type = AdClicked.self
    @objc public static let adCuePointsChanged: AdEvent.Type = AdCuePointsChanged.self
    @objc public static let adFirstQuartile: AdEvent.Type = AdFirstQuartile.self
    @objc public static let adLoaded: AdEvent.Type = AdLoaded.self
    @objc public static let adLog: AdEvent.Type = AdLog.self
    @objc public static let adMidpoint: AdEvent.Type = AdMidpoint.self
    @objc public static let adPaused: AdEvent.Type = AdPaused.self
    @objc public static let adResumed: AdEvent.Type = AdResumed.self
    @objc public static let adSkipped: AdEvent.Type = AdSkipped.self
    @objc public static let adStarted: AdEvent.Type = AdStarted.self
    @objc public static let adStreamLoaded: AdEvent.Type = AdStreamLoaded.self
    @objc public static let adTapped: AdEvent.Type = AdTapped.self
    @objc public static let adThirdQuartile: AdEvent.Type = AdThirdQuartile.self
    @objc public static let adDidProgressToTime: AdEvent.Type = AdDidProgressToTime.self
    @objc public static let adDidRequestPause: AdEvent.Type = AdDidRequestPause.self
    @objc public static let adDidRequestResume: AdEvent.Type = AdDidRequestResume.self
    @objc public static let webOpenerEvent: AdEvent.Type = WebOpenerEvent.self
    @objc public static let adWebOpenerWillOpenExternalBrowser: AdEvent.Type = AdWebOpenerWillOpenExternalBrowser.self
    @objc public static let adWebOpenerWillOpenInAppBrowser: AdEvent.Type = AdWebOpenerWillOpenInAppBrowser.self
    @objc public static let adWebOpenerDidOpenInAppBrowser: AdEvent.Type = AdWebOpenerDidOpenInAppBrowser.self
    @objc public static let adWebOpenerWillCloseInAppBrowser: AdEvent.Type = AdWebOpenerWillCloseInAppBrowser.self
    @objc public static let adWebOpenerDidCloseInAppBrowser: AdEvent.Type = AdWebOpenerDidCloseInAppBrowser.self
    /// Sent when an error occurs.
    @objc public static let error: AdEvent.Type = Error.self
    
    class AdBreakReady : AdEvent {}
    class AdBreakEnded : AdEvent {}
    class AdBreakStarted : AdEvent {}
    class AdAllCompleted : AdEvent {}
    class AdComplete : AdEvent {}
    class AdClicked : AdEvent {}
    class AdFirstQuartile : AdEvent {}
    class AdLoaded : AdEvent {}
    class AdLog : AdEvent {}
    class AdMidpoint : AdEvent {}
    class AdPaused : AdEvent {}
    class AdResumed : AdEvent {}
    class AdSkipped : AdEvent {}
    class AdStreamLoaded : AdEvent {}
    class AdTapped : AdEvent {}
    class AdThirdQuartile : AdEvent {}
    
    class AdStarted : AdEvent {
        convenience init(adInfo: AdInfo) {
            self.init([AdEventDataKeys.AdInfo: adInfo])
        }
    }
    
    class AdCuePointsChanged: AdEvent {
        convenience init(adCuePoints: AdCuePoints) {
            self.init([AdEventDataKeys.AdCuePoints: adCuePoints])
        }
    }
    
    class Error: AdEvent {
        convenience init(nsError: NSError) {
            self.init([AdEventDataKeys.Error: nsError])
        }
    }
    
    class AdDidProgressToTime: AdEvent {
        convenience init(mediaTime: TimeInterval, totalTime: TimeInterval) {
            self.init([AdEventDataKeys.MediaTime: NSNumber(value: mediaTime),
                       AdEventDataKeys.TotalTime: NSNumber(value: totalTime)])
        }
    }
    
    class AdDidRequestPause: AdEvent {}
    class AdDidRequestResume: AdEvent {}
    
    class WebOpenerEvent: AdEvent {
        convenience init(webOpener: NSObject!) {
            self.init([AdEventDataKeys.WebOpener: webOpener])
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
        static let MediaTime = "mediaTime"
        static let TotalTime = "totalTime"
        static let WebOpener = "webOpener"
        static let Error = "error"
        static let AdCuePoints = "adCuePoints"
        static let AdInfo = "adInfo"
    }
    
    // MARK: Ad Data Accessors
    
    /// MediaTime, PKEvent Ad Data Accessor
    @objc public var mediaTime: NSNumber? {
        return self.data?[AdEventDataKeys.MediaTime] as? NSNumber
    }
    
    /// TotalTime, PKEvent Ad Data Accessor
    @objc public var totalTime: NSNumber? {
        return self.data?[AdEventDataKeys.TotalTime] as? NSNumber
    }
    
    /// WebOpener, PKEvent Ad Data Accessor
    @objc public var webOpener: NSObject? {
        return self.data?[AdEventDataKeys.WebOpener] as? NSObject
    }
    
    /// Associated error from error event, PKEvent Ad Data Accessor
    @objc public var adError: NSError? {
        return self.data?[AdEventDataKeys.Error] as? NSError
    }
    
    /// Ad cue points, PKEvent Ad Data Accessor
    @objc public var adCuePoints: AdCuePoints? {
        return self.data?[AdEventDataKeys.AdCuePoints] as? AdCuePoints
    }
    
    /// Ad info, PKEvent Ad Data Accessor
    @objc public var adInfo: AdInfo? {
        return self.data?[AdEventDataKeys.AdInfo] as? AdInfo
    }
}

