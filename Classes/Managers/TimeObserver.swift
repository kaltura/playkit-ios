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

protocol TimeProvider: class {
    var currentTime: TimeInterval { get }
    var duration: TimeInterval { get }
}

public protocol TimeMonitor {
    
    /// Adds a periodic observer.
    ///
    /// - Parameters:
    ///   - interval: The interval to invoke the handler.
    ///   - dispatchQueue: The dispatch queue to observe the events on.
    ///   - eventHandler: The handler to invoke on when the time comes.
    /// - Returns: A uuid token to represent the observation, used to later remove a single observation.
    func addPeriodicObserver(interval: TimeInterval, observeOn dispatchQueue: DispatchQueue?, using eventHandler: @escaping (TimeInterval) -> Void) -> UUID
    
    /// Adds a boundary observer.
    ///
    /// - Parameters:
    ///   - times: The times to use the event handler.
    ///   - dispatchQueue: The dispatch queue to observe the events on.
    ///   - eventHandler: The handler to invoke on when the time comes.
    /// - Returns: A uuid token to represent the observation, used to later remove a single observation.
    func addBoundaryObserver(times: [TimeInterval], observeOn dispatchQueue: DispatchQueue?, using eventHandler: @escaping (TimeInterval, Double) -> Void) -> UUID
    
    /// removes a single periodic observer using the uuid provided when added the observation.
    func removePeriodicObserver(_ token: UUID)
    
    /// removes a single boundary observer using the uuid provided when added the observation.
    func removeBoundaryObserver(_ token: UUID)
    
    /// Removes all the periodic observers.
    func removePeriodicObservers()
    
    /// Removes all the boundary observers.
    func removeBoundaryObservers()
}

/// `PeriodicObservation` represent an observation over a specific interval.
/// Can have multiple observations on the same inteval.
struct PeriodicObservation: Hashable {
    let interval: Int
    var observations: [TimeObservation]
    
    init(interval: Int, observations: [TimeObservation]) {
        self.interval = interval
        self.observations = observations
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(interval)
    }
    
    public static func == (lhs: PeriodicObservation, rhs: PeriodicObservation) -> Bool {
        return lhs.interval == rhs.interval
    }
}

/// `TimeObservation` object represents a single time observation, identifiable by token
struct TimeObservation {
    let block: (TimeInterval) -> Void
    let dispatchQueue: DispatchQueue
    let token = UUID()
}

/// `BoundaryObservation` object represents a single boundary observation, identifiable by token
struct BoundaryObservation {
    let block: (TimeInterval, Double) -> Void
    let dispatchQueue: DispatchQueue
    let token: UUID
}

/// `TimeObserver` is used to observe time changes both periodic and boundary.
/// 
/// For performance reasons we are using one timer with 100ms interval as our base
/// and only timers in 100ms intervals can be used for example 0.5s 1s 1.1s are good.
/// In case and interval is not divisable by 100ms we will round it down for example: 1.565s will be changed to 1.5s interval.
///
/// Using 100ms interval gives us error margin of 100ms at most.
///
/// In order to not go over all the observation every time we are building a special dictionary
/// with interval values and the related boundary/periodic observers, 
/// this way only one fetch is made which is between O(1) and O(log n) where n is number of observations.
class TimeObserver: TimeMonitor {
    
    let interval: Int = 100
    let dispatchTimeInterval: DispatchTimeInterval = .milliseconds(100)
    /// the dispatch queue that we will receive the event block on.
    let dispatchQueue = DispatchQueue(label: "com.kaltura.playkit.time-observer")
    /// The timer source that will be used to fire the events.
    var dispatchTimer: DispatchSourceTimer?
    
    // Should the TimeObserver be active?
    var enabled = false {
        didSet {
            startStopTimer()
        }
    }
    
    /// all boundary observations, mapped by time in [millis: observation]
    var boundaryObservations = [Int64: [BoundaryObservation]]() {
        didSet {
            self.startStopTimer()
        }
    }
    /// The next closest boundary to cross, updates on stop/seek/boundary crossed.
    var nextBoundary: (time: Int64, observations: [BoundaryObservation])?
    
    /// all periodic observations (set of unique intervals)
    var periodicObservations = Set<PeriodicObservation>() {
        didSet {
            self.startStopTimer()
        }
    }
    /// mapping betweeen an interval and his relevant observations.
    /// used to track numerous timer cycles using only 1 timer.
    /// for example 2 timers: 1s interval and 2s interval, when the 2s interval arrives we need to invoke both handlers.
    var periodicObservationsMap = [Int: [PeriodicObservation]]()
    
    /// the highest interval we have in the observations used to reset the cycles.
    var maxInterval: Int = 0
    /// number of cycles we observed, used to invoke multiple intervals with one timer.
    var cycles: Int = 1
    var lastObservedTime: TimeInterval = -1
    weak var timeProvider: TimeProvider?
    
    init(timeProvider: TimeProvider) {
        self.timeProvider = timeProvider
    }
    
    deinit {
        self.periodicObservations.removeAll()
        self.periodicObservationsMap.removeAll()
        self.boundaryObservations.removeAll()
        self.stopTimer()
        self.dispatchTimer = nil
        PKLog.debug("time observer was deinit")
    }
    
    /************************************************************/
    // MARK: - TimeMonitor
    /************************************************************/
    
    func addPeriodicObserver(interval: TimeInterval, observeOn dispatchQueue: DispatchQueue?, using eventHandler: @escaping (TimeInterval) -> Void) -> UUID {
        // calculate interval in millis and remove reminder to make sure intervals are in 100ms gaps
        var intervalMs = Int(interval * 1000) - (Int(interval * 1000) % 100)
        // make sure intervalMs is not 0 if 0 give 100 instead.
        intervalMs = intervalMs == 0 ? 100 : intervalMs
        let dispatch = dispatchQueue ?? DispatchQueue.main
        if periodicObservations.count == 0 { // first observation just add
            self.maxInterval = intervalMs
            let timeObservation = TimeObservation(block: eventHandler, dispatchQueue: dispatch)
            let periodicObservation = PeriodicObservation(interval: intervalMs, observations: [timeObservation])
            self.periodicObservations.insert(periodicObservation)
            self.periodicObservationsMap[intervalMs] = [periodicObservation]
            return timeObservation.token
        } else if let periodicObservations = self.periodicObservationsMap[intervalMs] { // we already have this interval
            // get the observation with same interval
            var periodicObservation = periodicObservations.first(where: { $0.interval == intervalMs })!
            // add the observation
            let timeObservation = TimeObservation(block: eventHandler, dispatchQueue: dispatch)
            periodicObservation.observations.append(timeObservation)
            // periodic observation is a struct so in order to make the change we must remove and insert again
            self.periodicObservations.remove(periodicObservation)
            self.periodicObservations.insert(periodicObservation)
            self.updatePeriodicObservationsMap()
            return timeObservation.token
        } else { // not the first and we don't have this interval yet
            if intervalMs > self.maxInterval {
                self.maxInterval = intervalMs
            }
            let timeObservation = TimeObservation(block: eventHandler, dispatchQueue: dispatch)
            self.periodicObservations.insert(PeriodicObservation(interval: intervalMs, observations: [timeObservation]))
            self.updatePeriodicObservationsMap()
            return timeObservation.token
        }
    }
    
    func addBoundaryObserver(times: [TimeInterval], observeOn dispatchQueue: DispatchQueue?, using eventHandler: @escaping (TimeInterval, Double) -> Void) -> UUID {
        let token = UUID()
        for time in times {
            // We need to make boundaries within the interval difference stack together to make sure we call them together when needed.
            // We do this by making the time be fixed to the upper value of the interval.
            // For example: 1.234 will turn to 1.3, 10.578 will turn into 10.6.
            let timeMs = Int64(time * 1000) // the time millis in Int
            let fixedTime: Int64 = timeMs % Int64(interval) == 0 ? timeMs : timeMs - (timeMs % Int64(interval)) + Int64(interval)
            
            let observation = BoundaryObservation(block: eventHandler, dispatchQueue: dispatchQueue ?? DispatchQueue.main, token: token)
            // if we already have boundary observations for this time
            if var boundaryObservations = self.boundaryObservations[fixedTime] {
                boundaryObservations.append(observation)
                self.boundaryObservations[fixedTime] = boundaryObservations
            } else { // first observation
                self.boundaryObservations[fixedTime] = [observation]
            }
        }
        self.updateNextBoundary()
        return token
    }
    
    func removePeriodicObserver(_ token: UUID) {
        // check if observation with this token exists
        guard var periodicObservation = periodicObservations.first(where: { $0.observations.contains(where: { $0.token == token }) }) else { return }
        if periodicObservation.observations.count > 1 {
            // can force unwrap because we made sure in the guard observations contains the token.
            periodicObservation.observations.remove(at: periodicObservation.observations.firstIndex(where: { $0.token == token })!)
            // periodic observation is a struct so in order to make the change we must remove and insert again
            self.periodicObservations.remove(periodicObservation)
            self.periodicObservations.insert(periodicObservation)
        } else { // only one observation just remove the periodic observation
            self.periodicObservations.remove(periodicObservation)
        }
        // update periodic observation map after removing one the of periodic observers
        self.updatePeriodicObservationsMap()
    }
    
    func removeBoundaryObserver(_ token: UUID) {
        // iterate over all observations
        for (interval, observations) in self.boundaryObservations {
            // check if observation with the same token exists
            guard observations.contains(where: { $0.token == token }) else { continue }
            // update the observations with all observations with different token
            let observationsToKeep = observations.filter({ $0.token != token })
            if observationsToKeep.count == 0 {
                self.boundaryObservations[interval] = nil
            } else {
                self.boundaryObservations[interval] = observationsToKeep
            }
        }
        // update next boundary after boundary was removed
        self.updateNextBoundary()
    }
    
    func removePeriodicObservers() {
        self.periodicObservations.removeAll()
        self.updatePeriodicObservationsMap()
    }
    
    func removeBoundaryObservers() {
        self.boundaryObservations.removeAll()
        self.nextBoundary = nil
    }
    
    /************************************************************/
    // MARK: - Internal Implementation
    /************************************************************/
    
    func startTimer() {
        
        if !enabled {
            return
        }
        
        // reset the timer
        if let dispatchTimer = self.dispatchTimer {
            dispatchTimer.cancel()
        }
        // create the timer
        self.dispatchTimer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(rawValue: 0), queue: dispatchQueue)
        // set interval
        self.dispatchTimer!.schedule(deadline: .now(), repeating: dispatchTimeInterval)
        // set last reported time to current time before timer handler starts
        self.lastObservedTime = self.timeProvider?.currentTime ?? 0
        // set event handler
        self.dispatchTimer!.setEventHandler { [weak self] in
            guard let self = self, let timeProvider = self.timeProvider else { return }
            // take a snapshot of the current time to use for all checks
            let currentTime = timeProvider.currentTime
            let currentTimePercentage = currentTime / timeProvider.duration
            // only handle when current time is greater then 0, if we have 0 it means nothing to handle.
            guard currentTime > 0 else { return }
            // make sure current time is not equal last observed time (means we were stopped or paused or seeked)
            guard currentTime != self.lastObservedTime else {
                // update next boundary only once when we found out current time hasn't changed.
                if self.cycles > 1 {
                    self.updateNextBoundary()
                }
                // player stopped for some reason (paused/buffering/seeking/ended)
                self.cycles = 1
                return
            }
            // check periodic observations for current cycle
            self.handlePeriodicObservations(currentTime: currentTime)
            // if the difference between current time and last observed is greater then the threshold,
            // we probably had a seek and we shouldn't handle boundary observation
            let lastObservedTimeGap = currentTime - self.lastObservedTime
            if abs(lastObservedTimeGap) < (Double(self.interval / 100) * 2) { // jump is lower then threshold
                // check boundary observations
                self.handleBoundaryObservations(currentTime: currentTime, currentTimePercentage: currentTimePercentage)
            } else if lastObservedTimeGap < 0 { // seeked backward
                self.updateNextBoundary()
            } else { // seeked forward
                self.handleBoundaryObservations(currentTime: currentTime, currentTimePercentage: currentTimePercentage)
            }
            // update cycles count
            self.cycles += 1
            // if we reached the highest cycle reset
            if self.cycles > self.maxInterval / self.interval {
                self.cycles = 1
            }
            // update last observed time
            self.lastObservedTime = currentTime
        }
        // start the timer
        dispatchTimer!.resume()
    }
    
    func stopTimer() {
        if let dispatchTimer = dispatchTimer {
            dispatchTimer.cancel()
        }
        self.dispatchTimer = nil
        self.cycles = 1
    }
    
    /************************************************************/
    // MARK: - Private Implementation
    /************************************************************/
    
    private func updatePeriodicObservationsMap() {
        var periodicObservationsMap = [Int: [PeriodicObservation]]()
        let sortedPeriodicObservations = self.periodicObservations.sorted(by: { $0.interval < $1.interval })
        // update periodic observation to be sorted so next sort will be faster
        self.periodicObservations = Set(sortedPeriodicObservations)
        // update max interval
        guard let lastPeriodicObservationInterval = sortedPeriodicObservations.last?.interval else { return }
        self.maxInterval = lastPeriodicObservationInterval
        // update the periodic observation map
        for interval in stride(from: sortedPeriodicObservations.first!.interval, through: self.maxInterval, by: self.interval) {
            // all the items to add
            var itemsToAdd = [PeriodicObservation]()
            for periodicObservation in sortedPeriodicObservations {
                if interval % periodicObservation.interval == 0 {
                    itemsToAdd.append(periodicObservation)
                }
            }
            periodicObservationsMap[interval] = itemsToAdd
        }
        self.periodicObservationsMap = periodicObservationsMap
    }
    
    /// starts or stops the timer according to observations count, if no observations left stops the timer, 
    private func startStopTimer() {
        if self.periodicObservations.count == 0 && self.boundaryObservations.count == 0 {
            self.stopTimer()
        } else if self.dispatchTimer == nil {
            self.startTimer()
        }
    }
    
    private func handlePeriodicObservations(currentTime: TimeInterval) {
        if let periodicObservations = self.periodicObservationsMap[self.interval * self.cycles] {
            for periodicObservation in periodicObservations {
                for observation in periodicObservation.observations {
                    observation.dispatchQueue.async { 
                        observation.block(currentTime)
                    }
                }
            }
        }
    }
    
    private func handleBoundaryObservations(currentTime: TimeInterval, currentTimePercentage: Double) {
        if let nextBoundary = self.nextBoundary, nextBoundary.time >= Int64(self.lastObservedTime * 1000) && nextBoundary.time <= Int64(currentTime * 1000) {
            for observation in nextBoundary.observations {
                observation.dispatchQueue.async {
                    observation.block(currentTime, currentTimePercentage)
                }
            }
            self.updateNextBoundary()
        }
    }
    
    private func updateNextBoundary() {
        guard let currentTime = self.timeProvider?.currentTime else { return }
        var nextBoundary: (gap: Int64, boundaryTime: Int64, observations: [BoundaryObservation])? = nil
        for (boundaryTime, observations) in self.boundaryObservations {
            let gap = boundaryTime - Int64(currentTime * 1000)
            if nextBoundary == nil && gap > 0 {
                nextBoundary = (gap, boundaryTime, observations)
            } else if let nextB = nextBoundary, gap < nextB.gap && gap > 0 {
                nextBoundary = (gap, boundaryTime, observations)
            }
        }
        guard let nextB = nextBoundary else { return }
        self.nextBoundary = (nextB.boundaryTime, nextB.observations)
    }
}
