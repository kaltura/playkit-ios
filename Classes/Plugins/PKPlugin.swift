//
//  Plugin.swift
//  PlayKit
//
//  Created by Noam Tamim on 31/10/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

import UIKit
import AVFoundation

/**
 Used as a workaround for Apple bug with swift interoperability.
 
 There is an issue with initializing an object based on a protocol.Type with @objc attribute.
 Therefore we use a wrapper protocol for PKPlugin with @objc and then casting to a PKPlugin without the @objc attribute.
 
 - important:
 **should not be used! use PKPlugin to add a plugin**
 */
@objc public protocol Plugin {}

/// The `PKPlugin` protocol defines all the properties and methods required to define a plugin object.
public protocol PKPlugin: Plugin {
    /// The plugin name.
    static var pluginName: String { get }

    /// The player associated with the plugin
    unowned var player: Player { get set }
    
    init(player: Player, pluginConfig: Any?, messageBus: MessageBus)
    
    /// On first load. used for doing initialization for the first time with the media config.
    func onLoad(mediaConfig: MediaConfig)
    /// On update media. used to update the plugin with new media config when available
    func onUpdateMedia(mediaConfig: MediaConfig)
    func destroy()
}

/// `PKPluginError` represents plugins errors.
enum PKPluginError: PKError {
    
    case failedToCreatePlugin
    case missingPluginConfig(pluginName: String)
    
    static let Domain = PKErrorDomain.Plugin
    
    var code: Int {
        switch self {
        case .failedToCreatePlugin: return 2000
        case .missingPluginConfig: return 2001
        }
    }
    
    var errorDescription: String {
        switch self {
        case .failedToCreatePlugin: return "failed to create plugin, doesn't exist in registry"
        case .missingPluginConfig(let pluginName): return "Missing plugin config for plugin: \(pluginName)"
        }
    }
    
    var userInfo: [String: Any] {
        switch self {
        case .failedToCreatePlugin: return [:]
        case .missingPluginConfig(let pluginName): return [PluginNameKey : pluginName]
        }
    }
}
