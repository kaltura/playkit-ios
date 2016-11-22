//
//  PlayerEvent.swift
//  Pods
//
//  Created by Eliza Sapir on 14/11/2016.
//
//

import Foundation

public enum PlayerEvents: String, PKEvent {
    /**
     Sent when enough data is available that the media can be played, at least for a couple of frames.
     */
    case canPlay
    /**
     The metadata has loaded or changed, indicating a change in duration of the media. This is sent, for example, when the media has loaded enough that the duration is known.
     */
    case durationChange
    /**
     Sent when playback completes.
     */
    case ended
    /**
     The media's metadata has finished loading; all attributes now contain as much useful information as they're going to.
     */
    case loadedMetadata
    /**
     Sent when an error occurs.
     */
    case error
    /**
     Sent when playback of the media starts after having been paused; that is, when playback is resumed after a prior pause event.
     */
    case play
    /**
     Sent when playback is paused.
     */
    case pause
    /**
     Sent when the media begins to play (either for the first time, after having been paused, or after ending and then restarting).
     */
    case playing
    /**
     Sent when a seek operation begins.
     */
    case seeking
    /**
     Sent when a seek operation completes.
     */
    case seeked
}

public enum AdEvents: String, PKEvent {
    case adBreakReady
    case adBreakEnded
    case adBreakStarted
    case adAllCompleted
    case adComplete
    case adClicked
    case adCuepointsChanged
    case adFirstQuartile
    case adLoaded
    case adLog
    case adMidpoint
    case adPaused
    case adResumed
    case adSkipped
    case adStarted
    case adStreamLoaded
    case adTapped
    case adThirdQuartile
    case adWebOpenerWillOpenExternalBrowser
    case adWebOpenerWillOpenInAppBrowser
    case adWebOpenerDidOpenInAppBrowser
    case adWebOpenerWillCloseInAppBrowser
    case adWebOpenerDidCloseInAppBrowser
    case adDidProgressToTime
    case adDidRequestPause
    case adDidRequestResume
}
