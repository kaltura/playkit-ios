//
//  Response.swift
//  Pods
//
//  Created by Admin on 08/11/2016.
//
//

import UIKit


public struct Response<T> {
    
    public let data: T?
    public let error : Error?
    
}
