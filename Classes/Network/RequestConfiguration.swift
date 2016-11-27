//
//  RequestConfiguration.swift
//  Pods
//
//  Created by Admin on 10/11/2016.
//
//

import UIKit


var defaultTimeOut = 3.0
var defaultRetryCount = 3

public class RequestConfiguration {

    public var readTimeOut: Double = defaultTimeOut
    public var writeTimeOut: Double = defaultTimeOut
    public var connectTimeOut: Double = defaultTimeOut
    public var retryCount: Int = defaultRetryCount
    public var ignoreLocalCache: Bool = false
    
    public init() {
        
    }
}
