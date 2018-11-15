//
//  PluginEvent.swift
//  PlayKit
//
//  Created by Nilit Danan on 11/14/18.
//

import Foundation

@objc public class PluginEvent: PKEvent {
    
    /// Sent when a plugin error occurs.
    @objc public static let error: PluginEvent.Type = Error.self
    
    public class Error: PluginEvent {
        public convenience init(nsError: NSError) {
            self.init([EventDataKeys.error: nsError])
        }
        
        public convenience init(error: PKError) {
            self.init([EventDataKeys.error: error.asNSError])
        }
    }
}
