//
//  MessageBus.swift
//  Pods
//
//  Created by Eliza Sapir on 14/11/2016.
//
//

import Foundation

private struct Observation {
    weak var observer: AnyObject?
    let observeOn: DispatchQueue
    let block: (PKEvent) -> Void
}

@objc public class MessageBus: NSObject {
    private var observations = [String: [Observation]]()
    private let lock: AnyObject = UUID().uuidString as AnyObject
    
    @objc public func addObserver(_ observer: AnyObject, events: [PKEvent.Type], block: @escaping (PKEvent) -> Void) {
        self.add(observer: observer, events: events, block: block)
    }
    
    @objc public func addObserver(_ observer: AnyObject, events: [PKEvent.Type], observeOn dispatchQueue: DispatchQueue, block: @escaping (PKEvent)->Void) {
        self.add(observer: observer, events: events, observeOn: dispatchQueue, block: block)
    }
    
    private func add(observer: AnyObject, events: [PKEvent.Type], observeOn dispatchQueue: DispatchQueue = DispatchQueue.main, block: @escaping (PKEvent)->Void) {
        sync {
            PKLog.debug("Add observer: \(observer) for events: \(events)")
            events.forEach { (et) in
                let typeId = NSStringFromClass(et)
                var observationList: [Observation] = observations[typeId] ?? []
                observationList.append(Observation(observer: observer, observeOn: dispatchQueue, block: block))
                observations[typeId] = observationList
            }
        }
    }
    
    @objc public func removeObserver(_ observer: AnyObject, events: [PKEvent.Type]) {
        sync {
            PKLog.debug("Remove observer: \(observer) for events: \(events)")
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
        DispatchQueue.global().async { [weak self] in
            PKLog.info("Post event: \(String(describing: type(of: event)))")
            let typeId = NSStringFromClass(type(of: event))
            
            if let array = self?.observations[typeId] {
                // remove nil observers replace current observations with new ones, and call block with the event
                let newObservations = array.filter { $0.observer != nil }
                self?.observations[typeId] = newObservations
                newObservations.forEach { observation in
                    observation.observeOn.async {
                        observation.block(event)
                    }
                }
            }
        }
    }
    
    private func sync(block: () -> ()) {
        objc_sync_enter(lock)
        block()
        objc_sync_exit(lock)
    }
}
