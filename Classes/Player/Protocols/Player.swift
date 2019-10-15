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

@objc public protocol Player: BasicPlayer {
    
    /// The player's associated media entry.
    @objc weak var mediaEntry: PKMediaEntry? { get }
    
    /// The player's settings.
    @objc var settings: PKPlayerSettings { get }
    
    /// The current media format.
    @objc var mediaFormat: PKMediaSource.MediaFormat { get }
    
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
    
    /// Updates the styling from the settings textTrackStyling object
    @objc func updateTextTrackStyling()
    
    
    /// Indicates if current media is Live.
    ///
    /// - Returns: returns true if it's live.
    @objc func isLive() -> Bool
    
    /// Getter for playkit controllers.
    ///
    /// - Parameter type: Required class type.
    /// - Returns: Relevant controller if exist.
    @objc func getController(type: PKController.Type) -> PKController?
    
    /************************************************************/
    // MARK: - Time Observation
    /************************************************************/
    
    /// Adds a periodic time observer with specific interval
    ///
    /// - Parameters:
    ///   - interval: time interval for the periodic invocation.
    ///   - dispatchQueue: dispatch queue to observe changes on (nil value will use main).
    ///   - block: block to handle the observation.
    /// - Returns: A uuid token to represent the observation, used to later remove a single observation.
    @objc func addPeriodicObserver(interval: TimeInterval, observeOn dispatchQueue: DispatchQueue?, using block: @escaping (TimeInterval) -> Void) -> UUID
    
    /// Adds a boundary time observer for the selected boundaries in time (25%, 50%, 30s etc.)
    ///
    /// - Parameters:
    ///   - boundaries: boundary objects.
    ///   - dispatchQueue: dispatch queue to observe changes on (nil value will use main).
    ///   - block: block to handle the observation with the observed boundary, block returns (time, boundary percentage).
    /// - Returns: A uuid token to represent the observation, used to later remove a single observation.
    /// - Attention: if a boundary is crossed while seeking the observation **won't be triggered**.
    @objc func addBoundaryObserver(boundaries: [PKBoundary], observeOn dispatchQueue: DispatchQueue?, using block: @escaping (TimeInterval, Double) -> Void) -> UUID
    
    /// removes a single periodic observer using the uuid provided when added the observation.
    @objc func removePeriodicObserver(_ token: UUID)
    
    /// removes a single boundary observer using the uuid provided when added the observation.
    @objc func removeBoundaryObserver(_ token: UUID)
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

public protocol PlayerEngineWrapperProvider {
    func getPlayerEngineWrapper() -> PlayerEngineWrapper?
}
