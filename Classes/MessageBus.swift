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

private struct Observation {
    /// the observer of the event
    weak var observer: AnyObject?
    /// the dispatchQueue to observe the events on.
    let observeOn: DispatchQueue
    /// the block of code to be performed when event fires.
    let block: (PKEvent) -> Void
}

/// `MessageBus` object handles all event message observing and posting
@objc public class MessageBus: NSObject {
    
    private var observations = [String: [Observation]]()
    private let dispatchQueue = DispatchQueue(label: "com.kaltura.playkit.message-bus")
    
    @objc public func addObserver(_ observer: AnyObject, events: [PKEvent.Type], block: @escaping (PKEvent) -> Void) {
        self.add(observer: observer, events: events, block: block)
    }
    
    @objc public func addObserver(_ observer: AnyObject, events: [PKEvent.Type], observeOn dispatchQueue: DispatchQueue, block: @escaping (PKEvent) -> Void) {
        self.add(observer: observer, events: events, observeOn: dispatchQueue, block: block)
    }
    
    private func add(observer: AnyObject, events: [PKEvent.Type], observeOn dispatchQueue: DispatchQueue = DispatchQueue.main, block: @escaping (PKEvent) -> Void) {
        self.dispatchQueue.sync {
            PKLog.verbose("Add observer: \(String(describing: observer)) for events: \(String(describing: events))")
            events.forEach { (et) in
                let typeId = NSStringFromClass(et)
                var observationList: [Observation] = observations[typeId] ?? []
                observationList.append(Observation(observer: observer, observeOn: dispatchQueue, block: block))
                observations[typeId] = observationList
            }
        }
    }
    
    @objc public func removeObserver(_ observer: AnyObject, events: [PKEvent.Type]) {
        self.dispatchQueue.sync {
            PKLog.verbose("Remove observer: \(String(describing: observer)) for events: \(String(describing: events))")
            events.forEach { (et) in
                let typeId = NSStringFromClass(et)
                
                if let array = observations[typeId] {
                    observations[typeId] = array.filter { $0.observer! !== observer }
                } else {
                    PKLog.debug("removeObserver:: array is empty")
                }
            }
        }
    }
    
    @objc public func post(_ event: PKEvent) {
        self.dispatchQueue.sync { [weak self] in
            guard let self = self else { return }
            PKLog.verbose("post event: \(event), with data: \(event.data ?? [:])")
            let typeId = NSStringFromClass(type(of: event))
            
            if let array = self.observations[typeId] {
                // remove nil observers replace current observations with new ones, and call block with the event
                let newObservations = array.filter { $0.observer != nil }
                self.observations[typeId] = newObservations
                newObservations.forEach { observation in
                    observation.observeOn.async {
                        observation.block(event)
                    }
                }
            }
        }
    }
}
