// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license,
// unless a different license for a particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import Foundation

// Timer extension to add block based timers without the need for Timer's selector.
public extension Timer {
    
    /// Create a timer that will call `block` after interval once.
    class func after(_ interval: TimeInterval, _ block: @escaping () -> Void) -> Timer {
        let fireDate: CFAbsoluteTime = CFAbsoluteTimeGetCurrent() + interval
        let timer: Timer = CFRunLoopTimerCreateWithHandler(kCFAllocatorDefault, fireDate, 0, 0, 0) { _ in
            block()
        }
        timer.start()
        return timer
    }
    
    /// Create a timer that will call `block` every interval.
    class func every(_ interval: TimeInterval, _ block: @escaping () -> Void) -> Timer {
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
