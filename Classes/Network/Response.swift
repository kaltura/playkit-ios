//
//  Response.swift
//  Pods
//
//  Created by Admin on 08/11/2016.
//
//

import UIKit


public struct ResponseElemnt<T> {
    
    public let response: T?
    public let succedded: Bool
    public let error : Error?
    
}
