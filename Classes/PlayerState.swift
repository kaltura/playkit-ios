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
/// Sent when player's state loading.
    case loading
/// Sent when player's state ready.
    case ready
/// Sent when player's state buffering.
    case buffering
/// Sent when player's state errored.    
    case error
}
