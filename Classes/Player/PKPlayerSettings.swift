//
//  PKPlayerSettings.swift
//  Pods
//
//  Created by Gal Orlanczyk on 14/08/2017.
//
//

import Foundation

typealias SettingsChange = ((PlayerSettingsType) -> Void)

@objc public class PKNetworkSettings: NSObject {
    
    var onChange: SettingsChange?
    
    @objc public var preferredPeakBitRate: Double = 0 {
        didSet {
            self.onChange?(.preferredPeakBitRate(preferredPeakBitRate))
        }
    }
}

enum PlayerSettingsType {
    case preferredPeakBitRate(Double)
}

/************************************************************/
// MARK: - PKPlayerSettings
/************************************************************/

/// `PKPlayerSettings` object used as default configuration values for players.
@objc public class PKPlayerSettings: NSObject {
    
    var onChange: SettingsChange? {
        didSet {
            self.network.onChange = onChange
        }
    }
    
    /// The settings for network data consumption.
    @objc public var network = PKNetworkSettings()
    
    @objc public var contentRequestAdapter: PKRequestParamsAdapter? = KalturaPlaybackRequestAdapter()
    
    @objc public func createCopy() -> PKPlayerSettings {
        let copy = PKPlayerSettings()
        copy.network = self.network
        copy.contentRequestAdapter = self.contentRequestAdapter
        return copy
    }
}

extension PKPlayerSettings: NSCopying {
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return self.createCopy()
    }
}

