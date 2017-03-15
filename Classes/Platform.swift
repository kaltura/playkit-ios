//
//  Platform.swift
//  Pods
//
//  Created by Gal Orlanczyk on 03/03/2017.
//
//

import Foundation

struct Platform {
    static let isSimulator: Bool = {
        var isSim = false
        #if arch(i386) || arch(x86_64)
            isSim = true
        #endif
        return isSim
    }()
}
