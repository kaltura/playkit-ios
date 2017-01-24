//
//  ObjCEventAdapter.swift
//  Pods
//
//  Created by Noam Tamim on 23/01/2017.
//
//

import UIKit

public class PlayerEvent_playing: PKEvent, PKBridgedEvent {
    public required init(_ event: PKEvent) {}
    static let realType: PKEvent.Type = PlayerEvents.playing.self
}

public class PlayerEvent_durationChanged: PKEvent, PKBridgedEvent {
    static let realType: PKEvent.Type = PlayerEvents.durationChange.self
    private let realEvent: PlayerEvents.durationChange

    public var duration: TimeInterval {
        return realEvent.duration
    }

    public required init(_ event: PKEvent) {
        self.realEvent = event as! PlayerEvents.durationChange
    }
}


