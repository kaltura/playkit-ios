//
//  OttEvent.swift
//  Pods
//
//  Created by Oded Klein on 15/12/2016.
//
//

import UIKit

/// OTT Event
public class OttEvent : PKEvent {
    
    class Concurrency : OttEvent {}
    /// represents the Concurrency event Type.
    /// Concurrency events fire when more then the allowed connections are exceeded.
    public static let concurrency: OttEvent.Type = Concurrency.self
}
