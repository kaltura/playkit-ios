//
//  PlayerEvent.swift
//  Pods
//
//  Created by Eliza Sapir on 14/11/2016.
//
//
import Foundation

public class PlayerEvents: PKEvent {
    
    // All events EXCLUDING error. Assuming error events are treated differently.
    public static let allEventTypes: [PlayerEvents.Type] = [
        canPlay.self, durationChange.self, ended.self, loadedMetadata.self,
        play.self, pause.self, playing.self, seeking.self, seeked.self, stateChanged.self
    ]
    
    /**
     Sent when enough data is available that the media can be played, at least for a couple of frames.
     */
    public class canPlay : PlayerEvents {}
    /**
     The metadata has loaded or changed, indicating a change in duration of the media. This is sent, for example, when the media has loaded enough that the duration is known.
     */
    public class durationChange : PlayerEvents {
        public var duration: TimeInterval
        
        init(duration: TimeInterval) {
            self.duration = duration
        }
    }
    /**
     Sent when playback completes.
     */
    public class ended : PlayerEvents {}
    /**
     The media's metadata has finished loading; all attributes now contain as much useful information as they're going to.
     */
    public class loadedMetadata : PlayerEvents {}
    /**
     Sent when an error occurs.
     */
    public class error : PlayerEvents {}
    /**
     Sent when playback of the media starts after having been paused; that is, when playback is resumed after a prior pause event.
     */
    public class play : PlayerEvents {}
    /**
     Sent when playback is paused.
     */
    public class pause : PlayerEvents {}
    
    /**
     Sent when the media begins to play (either for the first time, after having been paused, or after ending and then restarting).
     */
    public class playing : PlayerEvents {}
    
    /**
     Sent when a seek operation begins.
     */
    public class seeking : PlayerEvents {}
   
    /**
     Sent when a seek operation completes.
     */
    public class seeked : PlayerEvents {}
    
    /**
     Sent when tracks available.
     */
    public class tracksAvailable : PlayerEvents {
        public var tracks: PKTracks
        
        public init(tracks: PKTracks) {
            self.tracks = tracks
        }
    }
    
    /**
     Sent when Playback Params Updated.
     */
    public class playbackParamsUpdated : PlayerEvents {
        public var currentBitrate: Double
        
        init(currentBitrate: Double) {
            self.currentBitrate = currentBitrate
        }
    }

    /**
     Sent when player state is changed.
     */
    public class stateChanged : PlayerEvents {
        public var newState: PlayerState
        public var oldState: PlayerState
        
        public init(newState: PlayerState, oldState: PlayerState) {
            self.newState = newState
            self.oldState = oldState
        }
    }
}

public class AdEvents: PKEvent {
    
    public static let allEventTypes: [AdEvents.Type] = [
        adBreakReady.self, adBreakEnded.self, adBreakStarted.self, adAllCompleted.self, adComplete.self, adClicked.self, adCuepointsChanged.self, adFirstQuartile.self, adLoaded.self, adLog.self, adMidpoint.self, adPaused.self, adResumed.self, adSkipped.self, adStarted.self, adStreamLoaded.self, adTapped.self, adThirdQuartile.self, adDidProgressToTime.self, adDidRequestPause.self, adDidRequestResume.self, adWebOpenerWillOpenExternalBrowser.self, adWebOpenerWillOpenInAppBrowser.self, adWebOpenerDidOpenInAppBrowser.self, adWebOpenerWillCloseInAppBrowser.self, adWebOpenerDidCloseInAppBrowser.self 
    ]
    
    public class adBreakReady : AdEvents {}
    public class adBreakEnded : AdEvents {}
    public class adBreakStarted : AdEvents {}
    public class adAllCompleted : AdEvents {}
    public class adComplete : AdEvents {}
    public class adClicked : AdEvents {}
    public class adCuepointsChanged : AdEvents {}
    public class adFirstQuartile : AdEvents {}
    public class adLoaded : AdEvents {}
    public class adLog : AdEvents {}
    public class adMidpoint : AdEvents {}
    public class adPaused : AdEvents {}
    public class adResumed : AdEvents {}
    public class adSkipped : AdEvents {}
    public class adStarted : AdEvents {}
    public class adStreamLoaded : AdEvents {}
    public class adTapped : AdEvents {}
    public class adThirdQuartile : AdEvents {}
    
    public class adDidProgressToTime : AdEvents {
        public let mediaTime, totalTime: TimeInterval
        init(mediaTime: TimeInterval, totalTime: TimeInterval) {
            self.mediaTime = mediaTime
            self.totalTime = totalTime
        }
        
        public required init() {
            fatalError("init() has not been implemented")
        }
    }
    public class adDidRequestPause : AdEvents {}
    public class adDidRequestResume : AdEvents {}
    
    public class WebOpenerEvent : AdEvents {
        let webOpener: NSObject
        public init(webOpener: NSObject!) {
            self.webOpener = webOpener
        }
        public required init() {
            fatalError("init() has not been implemented")
        }
    }
    
    public class adWebOpenerWillOpenExternalBrowser : WebOpenerEvent {}
    public class adWebOpenerWillOpenInAppBrowser : WebOpenerEvent {}
    public class adWebOpenerDidOpenInAppBrowser : WebOpenerEvent {}
    public class adWebOpenerWillCloseInAppBrowser : WebOpenerEvent {}
    public class adWebOpenerDidCloseInAppBrowser : WebOpenerEvent {}
    
    
    
    public required override init() {}
}
