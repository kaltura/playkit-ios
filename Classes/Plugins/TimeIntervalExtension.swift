//
//  TimeIntervalExtension.swift
//  Pods
//
//  Created by Oded Klein on 25/12/2016.
//
//

import UIKit

extension TimeInterval {
    
    var epoch: Int64 {
        if !self.isNaN && !self.isInfinite {
            return Int64(self * 1000)
        }
        return 0
    }
    
    func toInt32() -> Int32 {
        if !self.isNaN && !self.isInfinite {
            return Int32(self)
        }
        return 0
    }
}
