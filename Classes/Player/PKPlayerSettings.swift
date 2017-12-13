// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

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

@objc public enum TrackSelectionMode: Int {
    case `default`
    case auto
    case selection
}

@objc public class PKTrackSelectionSettings: NSObject {
    // text selection settings
    @objc public var textSelectionMode: TrackSelectionMode = .default
    @objc public var textSelectionLanguage: String?
    @objc public var textSelectionTitle: String?
    // audio selection settings
    @objc public var audioSelectionMode: TrackSelectionMode = .default
    @objc public var audioSelectionLanguage: String?
    @objc public var audioSelectionTitle: String?
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
    @objc public var trackSelection = PKTrackSelectionSettings()
    
    @objc public var contentRequestAdapter: PKRequestParamsAdapter? = KalturaPlaybackRequestAdapter()
    
    @objc public func createCopy() -> PKPlayerSettings {
        let copy = PKPlayerSettings()
        copy.network = self.network
        copy.trackSelection = self.trackSelection
        copy.contentRequestAdapter = self.contentRequestAdapter
        return copy
    }
}

extension PKPlayerSettings: NSCopying {
    
    @objc public func copy(with zone: NSZone? = nil) -> Any {
        return self.createCopy()
    }
}

