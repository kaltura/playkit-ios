//
//  Result.swift
//  Pods
//
//  Created by Admin on 08/11/2016.
//
//

import UIKit


public class Result<T>: NSObject {
    
    public var data: T? = nil
    public var error: Error? = nil
    
    public init(data:T?, error:Error?) {
        self.data = data
        self.error = error
    }
    
    public convenience init(data: T) {
        self.init(data: data, error: nil)
    }

    public convenience init(error: Error) {
        self.init(data: nil, error: error)
    }
}
