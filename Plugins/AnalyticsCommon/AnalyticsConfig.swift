//
//  AnalyticsConfig.swift
//  Pods
//
//  Created by Oded Klein on 24/11/2016.
//
//

import UIKit

@objc public class AnalyticsConfig: NSObject {
    
    @objc public var params: [String: Any]
    
    @objc public init(params: [String: Any]) {
        self.params = params
    }
}
