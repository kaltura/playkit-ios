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
        playListLoaded, playListStarted, playListEnded, playlistCountDownStart, playlistCountDownEnd, playlistLoopStateChanged, playlistLoopStateChanged, playlistAutoContinueStateChanged, playListError, playListLoadMediaError, playListCurrentPlayingItemChanged
    ]
    
    @objc public static let playListLoaded: PlaylistEvent.Type = PlayListLoaded.self
    @objc public static let playListStarted: PlaylistEvent.Type = PlayListStarted.self // ?
    @objc public static let playListEnded: PlaylistEvent.Type = PlayListEnded.self
    @objc public static let playlistCountDownStart: PlaylistEvent.Type = PlaylistCountDownStart.self // ?
    @objc public static let playlistCountDownEnd: PlaylistEvent.Type = PlaylistCountDownEnd.self // ?
    @objc public static let playlistLoopStateChanged: PlaylistEvent.Type = PlaylistLoopStateChanged.self
    @objc public static let playlistAutoContinueStateChanged: PlaylistEvent.Type = PlaylistAutoContinueStateChanged.self
    @objc public static let playListError: PlaylistEvent.Type = PlayListError.self
    @objc public static let playListLoadMediaError: PlaylistEvent.Type = PlayListLoadMediaError.self
    @objc public static let playListCurrentPlayingItemChanged: PlaylistEvent.Type = PlayListCurrentPlayingItemChanged.self
    
    public class PlayListLoaded: PlaylistEvent {}
    
    public class PlayListStarted: PlaylistEvent {}
    
    public class PlayListEnded: PlaylistEvent {}
    
    public class PlaylistCountDownStart: PlaylistEvent {}
    
    public class PlaylistCountDownEnd: PlaylistEvent {}
    
    public class PlaylistLoopStateChanged: PlaylistEvent {}
    
    public class PlaylistAutoContinueStateChanged: PlaylistEvent {}
    
    public class PlayListError: PlaylistEvent {
        public convenience init(nsError: NSError) {
            self.init([EventDataKeys.error: nsError])
        }
        
        public convenience init(error: PKError) {
            self.init([EventDataKeys.error: error.asNSError])
        }
    }
    
    public class PlayListLoadMediaError: PlaylistEvent {
        public convenience init(entryId: String, nsError: NSError) {
            self.init([EventDataKeys.entryId: entryId, EventDataKeys.error: nsError])
        }
        
        public convenience init(error: PKError) {
            self.init([EventDataKeys.error: error.asNSError])
        }
    }
    
    public class  PlayListCurrentPlayingItemChanged: PlaylistEvent {}
    
}
