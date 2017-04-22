//
//  Plugin.swift
//  PlayKit
//
//  Created by Noam Tamim on 31/10/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

import UIKit
import AVFoundation

/// The `PKPlugin` protocol defines all the properties and methods required to define a plugin object.
public protocol PKPlugin {
    /// The plugin name.
    static var pluginName: String { get }

    /// The player associated with the plugin
    weak var player: Player? { get }
    /// The messageBus associated with the plugin
    weak var messageBus: MessageBus? { get }
    /// On first load. used for doing initialization for the first time with the media config.
    init(player: Player, pluginConfig: Any?, messageBus: MessageBus) throws
    /// On update media. used to update the plugin with new media config when available.
    func onUpdateMedia(mediaConfig: MediaConfig)
    /// On update config. used to update the plugin config.
    func onUpdateConfig(pluginConfig: Any)
    /// Called on player destroy.
    func destroy()
}

public protocol PKPluginWarmUp {
    static func warmUp()
}
