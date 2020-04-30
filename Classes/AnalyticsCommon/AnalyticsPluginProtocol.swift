// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import Foundation

@objc public protocol AnalyticsPluginProtocol: PKPlugin {
    
    /// Indicates if it first play.
    var isFirstPlay: Bool { get set }
    
    /// List of events should be handled on plugin.
    var playerEventsToRegister: [PlayerEvent.Type] { get }
    
    /// Event registrasion based on playerEventsToRegister array.
    func registerEvents()
    
    /// unregister all registered events.
    func unregisterEvents()
}
