//
//  SessionProvider.swift
//  Pods
//
//  Created by Admin on 13/11/2016.
//
//

import UIKit

@objc public protocol SessionProvider: class {
    
    var serverURL: String { get }
    var partnerId: Int64 { get }
    
    func loadKS(completion: @escaping (String?, Error?) -> Void)
}


