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
    /// When this property is YES, whenever 1) the rate is set from zero to non-zero or 2) the playback buffer becomes empty and playback stalls, the player will attempt to determine if, at the specified rate, its currentItem will play to the end without interruptions. Should it determine that such interruptions would occur and these interruptions can be avoided by delaying the start or resumption of playback, the value of timeControlStatus will become AVPlayerTimeControlStatusWaitingToPlayAtSpecifiedRate and playback will start automatically when the likelihood of stalling has been minimized.
    ///
    /// You may want to set this property to NO when you need precise control over playback start times, e.g., when synchronizing multiple instances of AVPlayer. If the value of this property is NO, reasonForWaitingToPlay cannot assume a value of AVPlayerWaitingToMinimizeStallsReason. This implies that setting rate to a non-zero value in AVPlayerTimeControlStatusPaused will cause playback to start immediately as long as the playback buffer is not empty. When the playback buffer becomes empty during AVPlayerTimeControlStatusPlaying and playback stalls, playback state will switch to AVPlayerTimeControlStatusPaused and the rate will become 0.0.
    ///
    /// @available(iOS 10.0, *) via AVPlayer
    @objc public var automaticallyWaitsToMinimizeStalling = true {
        didSet {
            print("Nilit did set \(automaticallyWaitsToMinimizeStalling)")
            self.onChange?(.automaticallyWaitsToMinimizeStalling(automaticallyWaitsToMinimizeStalling))
        }
    }
    
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
    // text selection settings
    @objc public var textSelectionMode: TrackSelectionMode = .off
    @objc public var textSelectionLanguage: String?
    // audio selection settings
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
    /// @available(iOS 10.0, *)
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

