//
//  MessageBus.swift
//  Pods
//
//  Created by Eliza Sapir on 14/11/2016.
//
//

import Foundation

public class PKMessageBus: NSObject {
    typealias EventCallBack = (_ info: Any)->Void
    var callbacksByEventID: [String : [AnyHashable : [EventCallBack]]] = [:]
    
    func register(event: PKEvent, target: AnyHashable, callBack: @escaping EventCallBack) -> Void{
        var callbackDict: [AnyHashable : [EventCallBack]]? = nil
        
        if var dict: [AnyHashable : [EventCallBack]]? = self.callbacksByEventID[event.rawValue] {
            var callbacks: [EventCallBack]? = nil
            
            if var array: [EventCallBack]? = dict?[target] {
                // there is already such as arra
                callbacks = array
            }
            else{
                callbacks = [EventCallBack]()
            }
            
            callbacks!.append(callBack)
        }
    }
    
    func unRegister(event: PKEvent, target: AnyHashable) {
        if var callbackDict: [AnyHashable : [EventCallBack]] =
            self.callbacksByEventID[event.rawValue] {
            
            if var callbacks: [EventCallBack] = callbackDict[target] {
                callbackDict.removeValue(forKey: target)
            }
        }
    }
    
    func post(event: PKEvent, info:Any) {
        for (target, callbacksArray) in callbacksByEventID {
            if let callbacks: [EventCallBack] = callbacksArray[event.rawValue]{
                for callback : EventCallBack in callbacks {
                    callback(info)
                }
                
            }
        }
    }
}
