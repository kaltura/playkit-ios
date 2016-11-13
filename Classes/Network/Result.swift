//
//  Result.swift
//  Pods
//
//  Created by Admin on 08/11/2016.
//
//

import UIKit


public class Result<T> {
    
    public var data: T? = nil
    public var error: Error? = nil
    
    public init(data:T?, error:Error?) {
        self.data = data
        self.error = error
    }
    
}
