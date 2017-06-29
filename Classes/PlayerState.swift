//
//  PlayerState.swift
//  Pods
//
//  Created by Eliza Sapir on 29/11/2016.
//
//

import Foundation

/// An PlayerState is an enum of different player states
@objc public enum PlayerState: Int {
/// Sent when player's state idle.
    case idle
/// Sent when player's state ready.
    case ready
/// Sent when player's state buffering.
    case buffering
/// Sent when player's state ended.
/// Same event sent when observing PlayerEvent.ended.
/// This state was attached to reflect current state and avoid unrelevant boolean.
    case ended
/// Sent when player's state errored.    
    case error
/// Sent when player's state unknown.
    case unknown = -1
}
