//
//  Plugin.swift
//  PlayKit
//
//  Created by Noam Tamim on 31/10/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

import UIKit
import AVFoundation

@objc public protocol PKPlugin {
    
    static var pluginName: String { get }

    var mediaEntry: MediaEntry? { get set }

    init()

    
    func load(player: Player, pluginConfig: Any?, messageBus: MessageBus)
    
    func destroy()
}
