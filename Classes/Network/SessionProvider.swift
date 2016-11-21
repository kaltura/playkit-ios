//
//  SessionProvider.swift
//  Pods
//
//  Created by Admin on 13/11/2016.
//
//

import UIKit

public protocol SessionProvider {
    
    var serverURL: String { get }
    var partnerId: Int64 { get }
    var clientTag: String { get }
    var apiVersion: String { get }
    
    func refreshKS(completion: (_ result :Result<String>) -> Void)

    
    
    
}


