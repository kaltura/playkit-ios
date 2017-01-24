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
    let block: (PKEvent)->Void
    let bridgedEventType: PKBridgedEvent.Type?
}

public class MessageBus: NSObject {
    private var observations = [String: [Observation]]()
    private let lock: AnyObject = UUID().uuidString as AnyObject
    
    public func addObserver(_ observer: AnyObject, events: [PKEvent.Type], block: @escaping (PKEvent)->Void) {
        sync {
            events.forEach { (et) in
                
                let typeId: String
                let bet: PKBridgedEvent.Type?
                
                if et is PKBridgedEvent.Type {
                    bet = et as! PlayKit.PKBridgedEvent.Type
                    typeId = NSStringFromClass(bet!.realType)
                } else {
                    bet = nil
                    typeId = NSStringFromClass(et)
                }
                
                var array: [Observation]? = observations[typeId]
                
                if array == nil {
                    array = []
                }
                
                array!.append(Observation(observer: observer, block: block, bridgedEventType: bet))
                observations[typeId] = array
            }
        }
    }
    
    public func removeObserver(_ observer: AnyObject, events: [PKEvent.Type]) {
        sync {
            events.forEach { (et) in
                
                let typeId: String
                let bet: PKBridgedEvent.Type?
                
                if et is PKBridgedEvent.Type {
                    bet = et as! PlayKit.PKBridgedEvent.Type
                    typeId = NSStringFromClass(bet!.realType)
                } else {
                    bet = nil
                    typeId = NSStringFromClass(et)
                }
                
               // let typeId = NSStringFromClass(et)
                if let array = observations[typeId] {
                    observations[typeId] = array.filter { $0.observer! !== observer }
                } else {
                    print("removeObserver:: array is empty")
                }
            }
        }
    }
    
    public func post(_ event: PKEvent) {
        let typeId = NSStringFromClass(type(of:event))
        sync {
            // TODO: remove nil observers
            if let array = observations[typeId] {
                array.forEach {
                    if $0.observer != nil {
                        if let bet = $0.bridgedEventType {
                            $0.block(bet.init(event) as! PKEvent)
                        } else {
                            $0.block(event)
                        }
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

// MARK: - Objective-C Compatibility

protocol PKBridgedEvent: class {
    static var realType: PKEvent.Type {get}
    init(_ event: PKEvent)
}


