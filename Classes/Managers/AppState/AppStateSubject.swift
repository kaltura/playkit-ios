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

/// The interface of `AppStateSubject`, allows us to better divide the logic and mock easier.
public protocol AppStateSubjectProtocol: AppStateProviderDelegate {
    associatedtype InstanceType
    static var shared: InstanceType { get }
    /// Lock object for synchronizing access.
    var lock: AnyObject { get }
    /// The app state events provider.
    var appStateProvider: AppStateProvider { get }
    /// The current app state observers.
    var observers: [AppStateObserver] { get set }
    /// States whether currently observing.
    /// - note: when mocking set initial value to false.
    var isObserving: Bool { get set }
}

extension AppStateSubjectProtocol {
    /// Starts observing the app state events
    func startObservingAppState() {
        sync {
            // if not already observing and has more than 0 oberserver then start observing
            if !isObserving {
                PKLog.verbose("start observing app state")
                appStateProvider.addObservers()
                isObserving = true
            }
        }
    }
    
    /// Stops observing the app state events.
    func stopObservingAppState() {
        sync {
            if isObserving {
                PKLog.verbose("stop observing app state")
                appStateProvider.removeObservers()
                isObserving = false
            }
        }
    }
    
    /// Adds an observer to inform when state events are posted.
    public func add(observer: AppStateObservable) {
        sync {
            cleanObservers()
            PKLog.verbose("add observer, \(observer)")
            // if no observers were available start observing now
            if observers.count == 0 && !isObserving {
                startObservingAppState()
            }
            observers.append(AppStateObserver(observer))
        }
    }
    
    /// Removes an observer to stop being inform when state events are posted.
    public func remove(observer: AppStateObservable) {
        sync {
            cleanObservers()
            // search for the observer to remove
            for i in 0..<observers.count {
                if observers[i].observer === observer {
                    let removedObserver = observers.remove(at: i)
                    PKLog.verbose("removed observer, \(removedObserver)")
                    // if no more observers available stop observing
                    if observers.count == 0 && isObserving {
                        stopObservingAppState()
                    }
                    break
                }
            }
        }
    }
    
    /// Removes all observers and stop observing.
    func removeAllObservers() {
        sync {
            if observers.count > 0 {
                PKLog.verbose("remove all observers")
                observers.removeAll()
                stopObservingAppState()
            }
        }
    }
    
    /************************************************************/
    // MARK: AppStateProviderDelegate
    /************************************************************/
    
    public func appStateEventPosted(name: ObservationName) {
        sync {
            PKLog.verbose("app state event posted with name: \(name.rawValue)")
            for appStateObserver in self.observers {
                if let filteredObservations = appStateObserver.observer?.observations.filter({ $0.name == name }) {
                    for observation in filteredObservations {
                        observation.onObserve()
                    }
                }
            }
        }
    }
    
    // MARK: Private
    /// synchornized function
    private func sync(block: () -> ()) {
        objc_sync_enter(lock)
        block()
        objc_sync_exit(lock)
    }
    
    /// remove nil observers from our list
    private func cleanObservers() {
        self.observers = self.observers.filter { $0.observer != nil }
    }
}

/************************************************************/
// MARK: - AppStateSubject
/************************************************************/

/// The `AppStateSubject` class provides a way to add/remove application state observers.
///
/// - note: Subject is a class that is both observing and being observered.
/// In our case listening to events using the provider and posting using the obervations onObserve.
///
/// **For Unit-Testing:** When mocking this object just conform to the `AppStateSubjectProtocol`.
/// For firing events to observers manually use `appStateEventPosted(name: ObservationName)` with the observation name.
public final class AppStateSubject: AppStateSubjectProtocol {
    
    // singleton object and private init to prevent unwanted creation of more objects.
    public static let shared = AppStateSubject()
    private init() {
        self.appStateProvider = AppStateProvider()
        self.appStateProvider.delegate = self
    }
    
    public let lock: AnyObject = UUID().uuidString as AnyObject
    
    public var observers = [AppStateObserver]()
    public var appStateProvider: AppStateProvider
    public var isObserving = false
}

/************************************************************/
// MARK: - Types
/************************************************************/

/// Used to specify observation name
public typealias ObservationName = Notification.Name // used as typealias in case we will change type in the future.

/// represents a single observation with observation name as the type, and a block to perform when observing.
public struct NotificationObservation: Hashable {
    public init(name: ObservationName, onObserve: @escaping () -> Void) {
        self.name = name
        self.onObserve = onObserve
    }
    public var name: ObservationName
    public var onObserve: () -> Void
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

public func == (lhs: NotificationObservation, rhs: NotificationObservation) -> Bool {
    return lhs.name.rawValue == rhs.name.rawValue
}

public class AppStateObserver {
    weak var observer: AppStateObservable?
    init(_ observer: AppStateObservable) {
        self.observer = observer
    }
}

/// A type that provides a set of NotificationObservation to observe.
/// This interface defines the observations we would want in our class, for example a set of [willTerminate, didEnterBackground etc.]
public protocol AppStateObservable: AnyObject {
    var observations: Set<NotificationObservation> { get }
}
