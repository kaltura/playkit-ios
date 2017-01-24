//
//  PKEvent.swift
//  Pods
//
//  Created by Eliza Sapir on 14/11/2016.
//
//

import Foundation

public class PKEvent: NSObject {
    // Events that have payload must provide it as a dictionary for objective-c compat.
    public func data() -> [String: AnyObject]? {return nil}
}
