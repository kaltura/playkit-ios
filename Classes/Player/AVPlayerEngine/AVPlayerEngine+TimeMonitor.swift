//
//  AVPlayerEngine+TimeMonitor.swift
//  Pods
//
//  Created by Gal Orlanczyk on 21/08/2017.
//
//

import Foundation

extension AVPlayerEngine: TimeMonitor, TimeProvider {
    
    func addPeriodicObserver(interval: TimeInterval, observeOn dispatchQueue: DispatchQueue?, using eventHandler: @escaping (TimeInterval) -> Void) {
        self.timeObserver.addPeriodicObserver(interval: interval, observeOn: dispatchQueue, using: eventHandler)
    }
    
    func addBoundaryObserver(times: [TimeInterval], observeOn dispatchQueue: DispatchQueue?, using eventHandler: @escaping (TimeInterval, Double) -> Void) {
        self.timeObserver.addBoundaryObserver(times: times, observeOn: dispatchQueue, using: eventHandler)
    }
    
    func removePeriodicObservers() {
        self.timeObserver.removePeriodicObservers()
    }
    
    func removeBoundaryObservers() {
        self.timeObserver.removeBoundaryObservers()
    }
}
