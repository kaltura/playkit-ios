//
//  TimeIntervalExtension.swift
//  Pods
//
//  Created by Oded Klein on 25/12/2016.
//
//

import UIKit

extension TimeInterval {
    
    func toInt32() -> Int32 {
        if !self.isNaN && !self.isInfinite {
            return Int32(self)
        }
        return 0
    }
}
