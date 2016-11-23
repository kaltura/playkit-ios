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
    let block: (_ info: Any)->Void
}

public class MessageBus: NSObject {
    private var observations = [String: [Observation]]()
    private let lock: AnyObject = UUID().uuidString as AnyObject
    
    public func addObserver(_ observer: AnyObject, event: PKEvent, block: @escaping (_ info: Any)->Void) {
        sync {
            if var array: [Observation]? = observations[event.rawValue] {
                array!.append(Observation(observer: observer, block: block))
            } else {
                observations[event.rawValue] = [Observation(observer: observer, block: block)]
            }
        }
    }
    
    public func removeObserver(_ observer: AnyObject, event: PKEvent) {
        sync {
            if var array: [Observation]? = observations[event.rawValue] {
                array = array!.filter { $0.observer! !== observer }
            } else {
                print("removeObserver:: array is empty")
            }
        }
    }
    
    public func post(_ event: PKEvent) {
        sync {
            // TODO: remove nil observers
            if let array = observations[event.rawValue] {
                array.forEach {
                    if let observer = $0.observer {
                        $0.block(event)
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
