//
//  PlayerImp.swift
//  PlayKit
//
//  Created by Noam Tamim on 09/10/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

import Foundation

class PlayerImp : Player {
    public func pause() {
        
    }

    public func play() {
        
    }

    
    init() {
        
    }
    
    public var position: Int64 = 0
    
    public func release() {
        
    }
    
    var shouldPlay: Bool = false
    
    lazy var view: UIView = {
        
        return UIView()
    }()
    
    
    public func apply(_ config: PlayerConfig) -> Bool {
        return false
    }
    
    public func load(_ config: PlayerConfig) -> Bool {
        return false
    }
    
    
}
