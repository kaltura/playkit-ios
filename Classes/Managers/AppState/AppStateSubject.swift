//
//  AppStateSubject.swift
//  Pods
//
//  Created by Gal Orlanczyk on 19/01/2017.
//
//

import Foundation

/// The interface of `AppStateSubject`, allows us to better divide the logic and mock easier.
protocol AppStateSubjectProtocol: class, AppStateProviderDelegate {
    associatedtype InstanceType
    static var shared: InstanceType { get }
    /// Lock object for synchronizing access.
    var lock: AnyObject { get }
    /// The app state events provider.
    var appStateProvider: AppStateProvider { get }
    /// The current app state observers.
    var observers: [AppStateObservable] { get set }
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
                PKLog.trace("start observing app state")
                appStateProvider.addObservers()
                isObserving = true
            }
        }
    }
    
    /// Stops observing the app state events.
    func stopObservingAppState() {
        sync {
            if isObserving {
                PKLog.trace("stop observing app state")
                appStateProvider.removeObservers()
                isObserving = false
            }
        }
    }
    
    /// Adds an observer to inform when state events are posted.
    func add(observer: AppStateObservable) {
        sync {
            PKLog.trace("add observer, \(observer)")
            // if no observers were available start observing now
            if observers.count == 0 && !isObserving {
                startObservingAppState()
            }
            observers.append(observer)
        }
    }
    
    /// Removes an observer to stop being inform when state events are posted.
    func remove(observer: AppStateObservable) {
        sync {
            for i in 0..<observers.count {
                if observers[i] === observer {
                    let removedObserver = observers.remove(at: i)
                    PKLog.trace("removed observer, \(removedObserver)")
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
                PKLog.trace("remove all observers")
                observers.removeAll()
                stopObservingAppState()
            }
        }
    }
    
    /************************************************************/
    // MARK: AppStateProviderDelegate
    /************************************************************/
    
    func appStateEventPosted(name: ObservationName) {
        sync {
            PKLog.trace("app state event posted with name: \(name.rawValue)")
            for observer in self.observers {
                let filteredObservations = observer.observations.filter { $0.name == name }
                for observation in filteredObservations {
                    observation.onObserve()
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
final class AppStateSubject: AppStateSubjectProtocol {
    
    // singleton object and private init to prevent unwanted creation of more objects.
    static let shared = AppStateSubject()
    private init() {
        self.appStateProvider = AppStateProvider()
        self.appStateProvider.delegate = self
    }
    
    let lock: AnyObject = UUID().uuidString as AnyObject
    
    var observers = [AppStateObservable]()
    var appStateProvider: AppStateProvider
    var isObserving = false
}

/************************************************************/
// MARK: - Types
/************************************************************/

/// Used to specify observation name
typealias ObservationName = Notification.Name // used as typealias in case we will change type in the future.

/// represents a single observation with observation name as the type, and a block to perform when observing.
struct NotificationObservation: Hashable {
    var name: ObservationName
    var onObserve: () -> Void
    
    var hashValue: Int {
        return name.rawValue.hash
    }
}

func == (lhs: NotificationObservation, rhs: NotificationObservation) -> Bool {
    return lhs.name.rawValue == rhs.name.rawValue
}

/// A type that provides a set of NotificationObservation to observe.
/// This interface defines the observations we would want in our class, for example a set of [willTerminate, didEnterBackground etc.]
protocol AppStateObservable: AnyObject {
    var observations: Set<NotificationObservation> { get }
}
