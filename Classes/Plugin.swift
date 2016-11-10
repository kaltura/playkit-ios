//
//  Plugin.swift
//  PlayKit
//
//  Created by Noam Tamim on 31/10/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

import UIKit
import AVFoundation

public protocol Plugin {
    
    static var pluginName: String { get }

    init()
    
    func load(player: Player, config: AnyObject?)
    func release()
}
