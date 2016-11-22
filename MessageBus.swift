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
    let block: Any
}

public class MessageBus: NSObject {
    private static var observations = [String: [Observation]]()
    private static let lock: AnyObject = UUID().uuidString as AnyObject
    
    public static func addObserver(_ observer: AnyObject, event: PKEvent, block: @escaping (_ info: Any)->Void) {
        sync {
            if var array: [Observation]? = observations[event.rawValue] {
                array!.append(Observation(observer: observer, block: block))
            } else {
                observations[event.rawValue] = [Observation(observer: observer, block: block)]
            }
        }
    }
    
    public static func removeObserver(_ observer: AnyObject, event: PKEvent) {
        sync {
            if var array: [Observation]? = observations[event.rawValue] {
                array = array!.filter { $0.observer! !== observer }
            } else {
                print("removeObserver:: array is empty")
            }
        }
    }
    
    public static func post(_ event: PKEvent) {
        sync {
            if var array: [Observation]? = observations[event.rawValue] {
                array = array!.filter { $0.observer != nil } // Remove nil observers
                array!.forEach {
                    if let block = $0.block as? (_ info: Any)->Void {
                       block(event)                    }
                }
            }
        }
    }
    
    private static func sync(block: () -> ()) {
        objc_sync_enter(lock)
        block()
        objc_sync_exit(lock)
    }
}
