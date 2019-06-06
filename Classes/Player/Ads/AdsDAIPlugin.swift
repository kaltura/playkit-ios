

import Foundation

public protocol AdsDAIPlugin: AdsPlugin {
    
    /**
     *  Returns the content time without ads for a given stream time. Returns the given stream time
     *  for live streams.
     *
     *  @param streamTime   the stream time with inserted ads (in seconds)
     *
     *  @return the content time that corresponds with the given stream time once ads are removed
     */
    func contentTime(forStreamTime streamTime: TimeInterval) -> TimeInterval
    
    /**
     *  Returns the stream time with ads for a given content time. Returns the given content time
     *  for live streams.
     *
     *  @param contentTime   the content time without any ads (in seconds)
     *
     *  @return the stream time that corresponds with the given content time once ads are inserted
     */
    func streamTime(forContentTime contentTime: TimeInterval) -> TimeInterval
    
    /**
     *  Returns the previous cuepoint for the given stream time. Retuns nil if no such cuepoint exists.
     *  This is used to implement features like snap back, and called when the publisher detects that
     *  the user seeked in order to force the user to watch an ad break they may have skipped over.
     *
     *  @param streamTime   the stream time that was seeked to.
     *
     *  @return the previous Cuepoint for the given stream time.
     */
    func previousCuepoint(forStreamTime streamTime: TimeInterval) -> CuePoint?
    
    /**
     *  Returns if the upcoming ad can be played, the duration of the ad and the ad's end time.
     *  Returns nil in case no ad was found.
     *
     *  @param streamTime   the stream time to check for specific ad.
     *
     *  @return (canPlay, duration, endTime) if the ad can be played or not, duration of the ad, the end time of the ad.
     */
    func canPlayAd(atStreamTime streamTime: TimeInterval) -> (canPlay: Bool, duration: TimeInterval, endTime: TimeInterval)?
}
