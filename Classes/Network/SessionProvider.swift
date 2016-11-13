//
//  SessionProvider.swift
//  Pods
//
//  Created by Admin on 13/11/2016.
//
//

import UIKit

public protocol SessionProvider {
    var ks: String { get }
    var udid: String { get }
    var partnerId: Int64 { get }
    var serverURL: String { get }
}


