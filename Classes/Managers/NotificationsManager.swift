//
//  NotificationsManager.swift
//  Pods
//
//  Created by Gal Orlanczyk on 19/01/2017.
//
//

import Foundation

/// The `NotificationsManager` objects provides a mechanism for adding/removing observers within a program
final class NotificationsManager {
    
    let notificationCenter = NotificationCenter.default
    
    /// lock object for synchronizing access
    let lock: AnyObject = UUID().uuidString as AnyObject
    
    /// Holds all the notification observers tokens
    var observerTokens = [NSObjectProtocol]()
    
    
    /// Adds an observer for notification name, appends the token to the token list and returns it.
    /// - returns: The added observer token
    @discardableResult
    func addObserver(notificationName: Notification.Name,
                     object: Any? = nil,
                     queue: DispatchQueue = DispatchQueue.main,
                     using block: @escaping (Notification) -> Void) -> NSObjectProtocol {
        
        let observerToken = notificationCenter.addObserver(forName: notificationName,
                                                           object: object,
                                                           queue: OperationQueue.main,
                                                           using: block)
        sync {
            observerTokens.append(observerToken)
        }
        return observerToken
    }
    
    /// Removes an observer
    func remove(observer: AnyObject) {
        sync {
            notificationCenter.removeObserver(observer)
            for i in 0..<observerTokens.count {
                if observerTokens[i] === observer {
                    observerTokens.remove(at: i)
                    break
                }
            }
        }
    }
    
    /// Removes all Observers
    func removeAllObservers() {
        sync {
            for observerToken in observerTokens {
                notificationCenter.removeObserver(observerToken)
            }
            observerTokens.removeAll()
        }
    }
    
    // MARK: - Private
    /// synchornized function
    private func sync(block: () -> ()) {
        objc_sync_enter(lock)
        block()
        objc_sync_exit(lock)
    }
}

