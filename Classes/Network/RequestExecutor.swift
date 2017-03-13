//
//  RequestQueue.swift
//  Pods
//
//  Created by Admin on 10/11/2016.
//
//

import UIKit

// TODO: make @objc if needed in the future
public protocol RequestExecutor {
    
    func send(request: Request)
    func cancel(request: Request)
    func clean()
}
