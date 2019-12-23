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
    
    /// Indicates the desired limit of network bandwidth consumption for this item.
    ///
    /// Set preferredPeakBitRate to non-zero to indicate that the player should attempt to limit item playback to that bit rate, expressed in bits per second.
    /// If network bandwidth consumption cannot be lowered to meet the preferredPeakBitRate, it will be reduced as much as possible while continuing to play the item.
    ///
    /// @available(iOS 8.0, *) via AVPlayerItem
    @objc public var preferredPeakBitRate: Double = 0 {
        didSet {
            self.onChange?(.preferredPeakBitRate(preferredPeakBitRate))
        }
    }
    
    /// Indicates the media duration the caller prefers the player to buffer from the network ahead of the playhead to guard against playback disruption.
    ///
    /// The value is in seconds. If it is set to 0, the player will choose an appropriate level of buffering for most use cases.
    /// Note that setting this property to a low value will increase the chance that playback will stall and re-buffer, while setting it to a high value will increase demand on system resources.
    /// Note that the system may buffer less than the value of this property in order to manage resource consumption.
    ///
    /// @available(iOS 10.0, *) via AVPlayerItem
    @objc public var preferredForwardBufferDuration: Double = 0 {
        didSet {
            self.onChange?(.preferredForwardBufferDuration(preferredForwardBufferDuration))
        }
    }
    
    /// Indicates that the player is allowed to delay playback at the specified rate in order to minimize stalling
    ///
    /// For further details please see Apple's documentation: https://developer.apple.com/documentation/avfoundation/avplayer/1643482-automaticallywaitstominimizestal
    ///
    /// @available(iOS 10.0, tvOS 10.0, *) via AVPlayer
    @objc public var automaticallyWaitsToMinimizeStalling: Bool = true {
        didSet {
            self.onChange?(.automaticallyWaitsToMinimizeStalling(automaticallyWaitsToMinimizeStalling))
        }
    }
    
    /// Tells the player whether or not to buffer the media, or stop after initializing the asset and fetching the keys.
    ///
    /// Default value is true, initialize the asset, fetch the keys and buffer the media.
    /// If the value is set to false, the player will stop after initializing the asset and fetching the keys. A manual call to player startBuffering is needed.
    ///
    /// This comes in handy when you would like to divide between the views and initialize the media before the user interacts with the player to show it, start buffering and playing.
    /// In another case if you would like to start initializing the next media without buffering it, so that once the media is switched to the next one, it will be smother.
    @objc public var autoBuffer: Bool = true
    
    @objc public func createCopy() -> PKNetworkSettings {
        let copy = PKNetworkSettings()
        copy.preferredPeakBitRate = self.preferredPeakBitRate
        copy.preferredForwardBufferDuration = self.preferredForwardBufferDuration
        copy.automaticallyWaitsToMinimizeStalling = self.automaticallyWaitsToMinimizeStalling
        return copy
    }
}

@objc public enum TrackSelectionMode: Int, CustomStringConvertible {
    case off
    case auto
    case selection
    
    public init(_ mode: String) {
        switch mode {
        case "OFF": self = .off
        case "AUTO": self = .auto
        case "SELECTION": self = .selection
        default: self = .off
        }
    }
    
    public var description: String {
        switch self {
        case .off: return "OFF"
        case .auto: return "AUTO"
        case .selection: return "SELECTION"
        }
    }
    
    @available(*, deprecated, message: "Use description instead")
    public var asString: String {
        return self.description
    }
}

@objc public class PKTrackSelectionSettings: NSObject {
    // Text selection settings
    @objc public var textSelectionMode: TrackSelectionMode = .off
    @objc public var textSelectionLanguage: String?
    // Audio selection settings
    @objc public var audioSelectionMode: TrackSelectionMode = .off
    @objc public var audioSelectionLanguage: String?
}

enum PlayerSettingsType {
    case preferredPeakBitRate(Double)
    case preferredForwardBufferDuration(Double)
    case automaticallyWaitsToMinimizeStalling(Bool)
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
    
    @objc public var cea608CaptionsEnabled = false

    /// The settings for network data consumption.
    @objc public var network = PKNetworkSettings()
    @objc public var trackSelection = PKTrackSelectionSettings()
    @objc public var textTrackStyling = PKTextTrackStyling()
    
    @objc public var contentRequestAdapter: PKRequestParamsAdapter?
    @objc public var licenseRequestAdapter: PKRequestParamsAdapter?
    
    @objc public var fairPlayLicenseProvider: FairPlayLicenseProvider?
    @objc public var allowFairPlayOnExternalScreens = false
    
    /// If this value is set to true, playImmediatelyAtRate will be called.
    /// When the player's currentItem has a value of NO for playbackBufferEmpty, this method causes the value of rate to change to the specified rate, the value of timeControlStatus to change to AVPlayerTimeControlStatusPlaying, and the receiver to play the available media immediately, whether or not prior buffering of media data is sufficient to ensure smooth playback.
    /// If insufficient media data is buffered for playback to start (e.g. if the current item has a value of YES for playbackBufferEmpty), the receiver will act as if the buffer became empty during playback, except that no AVPlayerItemPlaybackStalledNotification will be posted.
    /// @available(iOS 10.0, tvOS 10.0, *)
    @objc public var shouldPlayImmediately = false
    
    @objc public func createCopy() -> PKPlayerSettings {
        let copy = PKPlayerSettings()
        copy.cea608CaptionsEnabled = self.cea608CaptionsEnabled
        copy.network = self.network.createCopy()
        copy.trackSelection = self.trackSelection
        copy.textTrackStyling = self.textTrackStyling
        copy.contentRequestAdapter = self.contentRequestAdapter
        copy.licenseRequestAdapter = self.licenseRequestAdapter
        return copy
    }
}

extension PKPlayerSettings: NSCopying {
    
    @objc public func copy(with zone: NSZone? = nil) -> Any {
        return self.createCopy()
    }
}

