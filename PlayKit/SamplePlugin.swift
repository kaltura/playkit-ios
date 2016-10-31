//
//  SamplePlugin.swift
//  PlayKit
//
//  Created by Noam Tamim on 31/10/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

import UIKit

public class SamplePlugin: Plugin {
    public static let pluginName = "Sample"

    public required init() {
        print("Initialized")
    }
    
    
    
    public func release() {
        
    }

    public func load(player: Player, config: PlayerConfig) {
        print("load", player, config)
    }
}
