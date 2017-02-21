//
//  PKTimer.swift
//  Pods
//
//  Created by Gal Orlanczyk on 31/01/2017.
//
//

import Foundation

// Timer extension to add block based timers without the need for Timer's selector.
extension Timer {
    
    /// Create a timer that will call `block` after interval once.
    public class func after(_ interval: TimeInterval, _ block: @escaping () -> Void) -> Timer {
        let fireDate: CFAbsoluteTime = CFAbsoluteTimeGetCurrent() + interval
        let timer: Timer = CFRunLoopTimerCreateWithHandler(kCFAllocatorDefault, fireDate, 0, 0, 0) { _ in
            block()
        }
        timer.start()
        return timer
    }
    
    /// Create a timer that will call `block` every interval.
    public class func every(_ interval: TimeInterval, _ block: @escaping () -> Void) -> Timer {
        let fireDate: CFAbsoluteTime = CFAbsoluteTimeGetCurrent() + interval
        let timer: Timer = CFRunLoopTimerCreateWithHandler(kCFAllocatorDefault, fireDate, interval, 0, 0) { _ in
            block()
        }
        timer.start()
        return timer
    }
    
    /// starts the timer on the selected RunLoop (default is `.current`) with the provided modes.
    func start(runLoop: RunLoop = .current, modes: RunLoopMode...) {
        let modes = modes.isEmpty ? [.defaultRunLoopMode] : modes
        
        for mode in modes {
            runLoop.add(self, forMode: mode)
        }
    }
    
}
