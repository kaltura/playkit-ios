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

extension PlayerController: TimeMonitor, TimeProvider {
    
    @objc public func addPeriodicObserver(interval: TimeInterval, observeOn dispatchQueue: DispatchQueue?, using eventHandler: @escaping (TimeInterval) -> Void) -> UUID {
        PKLog.debug("add periodic observer with interval: \(interval), on queue: \(String(describing: dispatchQueue))")
        let token = self.timeObserver.addPeriodicObserver(interval: interval, observeOn: dispatchQueue, using: eventHandler)
        PKLog.debug("periodic observer added with token: \(token.uuidString)")
        return token
    }
    
    @objc public func addBoundaryObserver(boundaries: [PKBoundary], observeOn dispatchQueue: DispatchQueue?, using block: @escaping (TimeInterval, Double) -> Void) -> UUID {
        return self.addBoundaryObserver(times: boundaries.map { $0.time }, observeOn: dispatchQueue, using: block)
    }
    
    @objc public func addBoundaryObserver(times: [TimeInterval], observeOn dispatchQueue: DispatchQueue?, using eventHandler: @escaping (TimeInterval, Double) -> Void) -> UUID {
        PKLog.debug("add boundary observer with times: \(times), on queue: \(String(describing: dispatchQueue))")
        let token = self.timeObserver.addBoundaryObserver(times: times, observeOn: dispatchQueue, using: eventHandler)
        PKLog.debug("boundary observer added with token: \(token.uuidString)")
        return token
    }
    
    @objc public func removePeriodicObserver(_ token: UUID) {
        PKLog.debug("remove periodic observer with token: \(token.uuidString)")
        self.timeObserver.removePeriodicObserver(token)
    }
    
    @objc public func removeBoundaryObserver(_ token: UUID) {
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
