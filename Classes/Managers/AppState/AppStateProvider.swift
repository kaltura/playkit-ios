//
//  AppStateProvider.swift
//  Pods
//
//  Created by Gal Orlanczyk on 19/01/2017.
//
//

import Foundation

/// The delegate of `AppStateProvider`, allows the delegate to inform on app state notifications.
public protocol AppStateProviderDelegate: class {
    /// fire this delegate function when received observation event.
    /// for every observer with the same observation event process the on observe block.
    func appStateEventPosted(name: ObservationName)
}

/// The interface of `AppStateProvider`, allows us to better divide the logic and mock easier.
public protocol AppStateProviderProtocol {
    var notificationsManager: NotificationsManager { get }
    /// Holds all the observation names we will be observing.
    /// If you want to observe more events add them here.
    var observationNames: Set<ObservationName> { get }
    weak var delegate: AppStateProviderDelegate? { get }
}

extension AppStateProviderProtocol {
    /// Add observers for the provided notification names.
    func addObservers() {
        observationNames.forEach { name in
            notificationsManager.addObserver(notificationName: name) { notification in
                self.delegate?.appStateEventPosted(name: notification.name)
            }
        }
    }
    
    /// Remove observers for the provided notification names.
    func removeObservers() {
        notificationsManager.removeAllObservers()
    }
    
}

/************************************************************/
// MARK: - AppStateProvider
/************************************************************/

/// The `AppStateProvider` is a provider for receiving events from the system about app states.
/// Used to seperate the events providing from the app state subject and enabling us to mock better.
public final class AppStateProvider: AppStateProviderProtocol {
    
    public init(delegate: AppStateProviderDelegate? = nil) {
        self.delegate = delegate
    }
    
    public var delegate: AppStateProviderDelegate?
    
    public let notificationsManager = NotificationsManager()
    
    public let observationNames: Set<ObservationName> = [
        .UIApplicationWillTerminate,
        .UIApplicationDidEnterBackground,
        .UIApplicationDidBecomeActive,
        .UIApplicationWillResignActive,
        .UIApplicationWillEnterForeground
    ]
    
}


