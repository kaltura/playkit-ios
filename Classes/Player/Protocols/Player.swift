// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import UIKit

@objc public protocol PlayerDelegate {
    @objc optional func playerShouldPlayAd(_ player: Player) -> Bool
}

@objc public protocol Player: BasicPlayer {
    
    /// The player's delegate.
    @objc weak var delegate: PlayerDelegate? { get set }
    
    /// The player's associated media entry.
    @objc weak var mediaEntry: PKMediaEntry? { get }
    
    /// The player's settings.
    @objc var settings: PKPlayerSettings { get }
    
    /// The player's session id. the `sessionId` is initialized when the player loads.
    @objc var sessionId: String { get }

    /// Add Observation to relevant event.
    @objc func addObserver(_ observer: AnyObject, event: PKEvent.Type, block: @escaping (PKEvent) -> Void)
    
    /// Add Observation to relevant events.
    @objc func addObserver(_ observer: AnyObject, events: [PKEvent.Type], block: @escaping (PKEvent) -> Void)
    
    /// Remove Observer for single event.
    @objc func removeObserver(_ observer: AnyObject, event: PKEvent.Type)
    
    /// Remove Observer for several events.
    @objc func removeObserver(_ observer: AnyObject, events: [PKEvent.Type])
    
    /// Update Plugin Config.
    @objc func updatePluginConfig(pluginName: String, config: Any)
    
    /// Getter for playkit controllers.
    ///
    /// - Parameter type: Required class type.
    /// - Returns: Relevant controller if exist.
    @objc func getController(type: PKController.Type) -> PKController?
}

extension Player {
    
    /// Getter for playkit controllers.
    ///
    /// - Parameter type: Required class type.
    /// - Returns: Relevant controller if exist.
    public func getController<T: PKController>(ofType type: T.Type) -> T? {
        return self.getController(type: type) as? T
    }
}

public protocol PlayerDecoratorProvider {
    func getPlayerDecorator() -> PlayerDecoratorBase?
}
