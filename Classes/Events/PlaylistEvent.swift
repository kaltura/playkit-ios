// ===================================================================================================
// Copyright (C) 2021 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================
//
//  PlaylistEvent.swift
//  PlayKit
//
//  Created by Sergii Chausov on 27.10.2021.
//

import Foundation

@objc public class PlaylistEvent: PKEvent {
    
    @objc public static let allEventTypes: [PlaylistEvent.Type] = [
        playlistLoaded, playlistStarted, playlistEnded, playlistCountdownStart, playlistCountdownEnd, playlistLoopStateChanged, playlistLoopStateChanged, playlistAutoContinueStateChanged, playlistError, playlistLoadMediaError, playlistCurrentPlayingItemChanged
    ]
    
    @objc public static let playlistLoaded: PlaylistEvent.Type = PlaylistLoaded.self
    @objc public static let playlistStarted: PlaylistEvent.Type = PlaylistStarted.self
    @objc public static let playlistEnded: PlaylistEvent.Type = PlaylistEnded.self
    @objc public static let playlistCountdownStart: PlaylistEvent.Type = PlaylistCountdownStart.self
    @objc public static let playlistCountdownEnd: PlaylistEvent.Type = PlaylistCountdownEnd.self
    @objc public static let playlistLoopStateChanged: PlaylistEvent.Type = PlaylistLoopStateChanged.self
    @objc public static let playlistAutoContinueStateChanged: PlaylistEvent.Type = PlaylistAutoContinueStateChanged.self
    @objc public static let playlistError: PlaylistEvent.Type = PlaylistError.self
    @objc public static let playlistLoadMediaError: PlaylistEvent.Type = PlaylistLoadMediaError.self
    @objc public static let playlistCurrentPlayingItemChanged: PlaylistEvent.Type = PlaylistCurrentPlayingItemChanged.self
    
    public class PlaylistLoaded: PlaylistEvent {}
    
    public class PlaylistStarted: PlaylistEvent {}
    
    public class PlaylistEnded: PlaylistEvent {}
    
    public class PlaylistCountdownStart: PlaylistEvent {
        public convenience init(countDownDuration: TimeInterval) {
            self.init([EventDataKeys.duration: NSNumber(value: countDownDuration)])
        }
    }
    
    public class PlaylistCountdownEnd: PlaylistEvent {}
    
    public class PlaylistLoopStateChanged: PlaylistEvent {}
    
    public class PlaylistAutoContinueStateChanged: PlaylistEvent {}
    
    public class PlaylistError: PlaylistEvent {
        public convenience init(nsError: NSError) {
            self.init([EventDataKeys.error: nsError])
        }
        
        public convenience init(error: PKError) {
            self.init([EventDataKeys.error: error.asNSError])
        }
    }
    
    public class PlaylistLoadMediaError: PlaylistEvent {
        public convenience init(entryId: String, nsError: NSError) {
            self.init([EventDataKeys.entryId: entryId, EventDataKeys.error: nsError])
        }
        
        public convenience init(error: PKError) {
            self.init([EventDataKeys.error: error.asNSError])
        }
    }
    
    public class  PlaylistCurrentPlayingItemChanged: PlaylistEvent {}
    
}
