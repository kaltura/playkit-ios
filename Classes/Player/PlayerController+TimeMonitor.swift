//
//  PlayerController+TimeMonitor.swift
//  PlayKit
//
//  Created by Gal Orlanczyk on 15/10/2017.
//

import Foundation

extension PlayerController: TimeMonitor, TimeProvider {
    
    public func addPeriodicObserver(interval: TimeInterval, observeOn dispatchQueue: DispatchQueue?, using eventHandler: @escaping (TimeInterval) -> Void) -> UUID {
        PKLog.debug("add periodic observer with interval: \(interval), on queue: \(String(describing: dispatchQueue))")
        let token = self.timeObserver.addPeriodicObserver(interval: interval, observeOn: dispatchQueue, using: eventHandler)
        PKLog.debug("periodic observer added with token: \(token.uuidString)")
        return token
    }
    
    public func addBoundaryObserver(boundaries: [PKBoundary], observeOn dispatchQueue: DispatchQueue?, using block: @escaping (TimeInterval, Double) -> Void) -> UUID {
        return self.addBoundaryObserver(times: boundaries.map { $0.time }, observeOn: dispatchQueue, using: block)
    }
    
    public func addBoundaryObserver(times: [TimeInterval], observeOn dispatchQueue: DispatchQueue?, using eventHandler: @escaping (TimeInterval, Double) -> Void) -> UUID {
        PKLog.debug("add boundary observer with times: \(times), on queue: \(String(describing: dispatchQueue))")
        let token = self.timeObserver.addBoundaryObserver(times: times, observeOn: dispatchQueue, using: eventHandler)
        PKLog.debug("boundary observer added with token: \(token.uuidString)")
        return token
    }
    
    public func removePeriodicObserver(_ token: UUID) {
        PKLog.debug("remove periodic observer with token: \(token.uuidString)")
        self.timeObserver.removePeriodicObserver(token)
    }
    
    public func removeBoundaryObserver(_ token: UUID) {
        PKLog.debug("remove boundary observer with token: \(token.uuidString)")
        self.timeObserver.removeBoundaryObserver(token)
    }
    
    func removePeriodicObservers() {
        PKLog.debug("remove all periodic observers")
        self.timeObserver.removePeriodicObservers()
    }
    
    func removeBoundaryObservers() {
        PKLog.debug("remove all boundary observers")
        self.timeObserver.removeBoundaryObservers()
    }
}
