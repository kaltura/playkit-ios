//
//  PKPlayerSettings.swift
//  Pods
//
//  Created by Gal Orlanczyk on 15/06/2017.
//
//

import Foundation
import AVFoundation

/************************************************************/
// MARK: - PKDataConsumptionMode
/************************************************************/

@objc public enum PKForwardBufferMode: Int {
    /// Optimizes the buffer size according to user engagement and video duration.
    /// The more the user watches the video the bigger the buffer size will get this allows to restrict data consumption
    /// while maintaining good video experience.
    ///
    /// **For example(numbers are not accurate they are used just as an example):**
    /// if a video duration is short and a user watched 1% a user can get buffer of size 22 seconds
    /// and when the user reaches 5% the buffer size will be 25 seconds and on 10% 30 seconds and so on until a certain limit.
    case userEngagement
    /// optimizes the buffer according the video duration.
    ///
    /// **For example(numbers are not accurate they are used just as an example):**
    /// for 10 minutes movie the buffer will be 35 seconds
    /// and for 20 minutes movie buffer will be 40 seconds.
    case duration
    /// optimizes the buffer according the video duration with custom provided range values. 
    /// if no ranges are provided will use the default ones.
    case durationCustom
    /// Custom optimization according to the provided `preferredForwardBufferDuration`.
    case custom
    /// No data optimization will use default values.
    case none
}

/************************************************************/
// MARK: - PKDataUsageSettings
/************************************************************/

@objc protocol PKDataUsageSettingsDelegate: class {
    func forwardBufferModeDidChange(newMode: PKForwardBufferMode)
    func preferredPeakBitRateDidChange(newValue: TimeInterval)
    func canUseNetworkResourcesForLiveStreamingWhilePausedDidChange(newValue: Bool)
}

@objc public class PKDataUsageSettings: NSObject {
    
    /// the data consumption mode, by default uses `userEngagement` mode.
    /// - important: available from iOS 10.0 and tvOS 10.0 for previous versions will ignore this value.
    @objc public var forwardBufferMode: PKForwardBufferMode = .userEngagement {
        didSet {
            if forwardBufferMode != oldValue {
                self.delegate?.forwardBufferModeDidChange(newMode: forwardBufferMode)
            }
        }
    }
    
    /// When using `dataConsumptionMode.durationCustom` values are taken from this property.
    /// If left empty while using this mode will use default logic values instead.
    @objc public var durationModeCustomRanges: PKForwardBufferDecisionRanges?
    
    /// The preferred forward buffer size (the maximum buffer limit).
    /// - Attention:
    ///     - Settings this to a value greater than 0 while a mode is selected will change the mode to `PKDataConsumptionMode.custom` 
    ///     and 0 will change it to `PKDataConsumptionMode.none`.
    ///     - Available from iOS 10.0 and tvOS 10.0 for previous versions will ignore this value.
    @objc public var preferredForwardBufferDuration: TimeInterval = 0 {
        didSet {
            if self.preferredForwardBufferDuration > 0 {
                self.forwardBufferMode = .custom
            } else {
                self.forwardBufferMode = .none
            }
        }
    }
    
    /// The desired limit, in bits per second, of network bandwidth consumption for this item.
    @objc public var preferredPeakBitRate: Double = 0 {
        didSet {
            if preferredPeakBitRate != oldValue {
                self.delegate?.preferredPeakBitRateDidChange(newValue: preferredPeakBitRate)
            }
        }
    }
    
    /// Indicates whether the player item can use network resources to keep playback state up to date while paused.
    @objc public var canUseNetworkResourcesForLiveStreamingWhilePaused = false {
        didSet {
            if canUseNetworkResourcesForLiveStreamingWhilePaused != oldValue {
                self.delegate?.canUseNetworkResourcesForLiveStreamingWhilePausedDidChange(newValue: canUseNetworkResourcesForLiveStreamingWhilePaused)
            }
        }
    }
    
    @objc weak var delegate: PKDataUsageSettingsDelegate?
}

/************************************************************/
// MARK: - PKMediaStartupMode
/************************************************************/

/// Adjust the startup mode of the asset.
///
/// Available for iOS 10 and above.
@objc public enum PKMediaStartupMode: Int {
    /// Normal start up, this is the default case.
    case normal
    /// Uses `preferredForwardBufferDuration` with small values to start the playback fast.
    /// - attention: might cause stalls on slow network.
    case fast
    /// Uses `preferredForwardBufferDuration` with small values to start the playback fast.
    /// In addition, limits the network using `preferredPeakBitRate`.
    /// This allows to start the video fast with a low rendition and when playback starts uses the data consumption settings.
    /// - attention:
    ///     - Might cause stalls on slow network.
    ///     - Uses `preferredPeakBitRate` if set in the settings otherwise uses a default value.
    case fastWithPeakBitRate
    
    /// the forward buffer duration for the selected mode
    var preferredForwardBufferDuration: TimeInterval {
        return 5
    }
}

/************************************************************/
// MARK: - PKAssetSettings
/************************************************************/

protocol PKAssetSettings {
    var dataUsageSettings: PKDataUsageSettings { get set }
    var startupMode: PKMediaStartupMode { get set }
}

extension AVPlayerItem {
    
    convenience init(pkAsset: PKAsset) {
        self.init(asset: pkAsset.avAsset)
        
        let settings = pkAsset.settings
        let settingsPreferredPeakBitRate = settings.dataUsageSettings.preferredPeakBitRate
        
        // setup the AVPlayerItem according to the startup mode + data usage settings
        switch pkAsset.settings.startupMode {
        case .fast:
            if #available(iOS 10.0, *) {
                self.preferredForwardBufferDuration = settings.startupMode.preferredForwardBufferDuration
            } else {
                PKLog.warning("can't set startup mode, preferred forward buffer is only supported on iOS 10 and above")
            }
        case .fastWithPeakBitRate:
            self.preferredPeakBitRate = settingsPreferredPeakBitRate > 0 ? settingsPreferredPeakBitRate : 800
            if #available(iOS 10.0, *) {
                self.preferredForwardBufferDuration = settings.startupMode.preferredForwardBufferDuration
            } else {
                PKLog.warning("can't set startup mode, preferred forward buffer is only supported on iOS 10 and above")
            }
        case .normal:
            if settingsPreferredPeakBitRate > 0 {
                self.preferredPeakBitRate = settingsPreferredPeakBitRate
            }
            let settingsPreferredForwardBufferDuration = settings.dataUsageSettings.preferredForwardBufferDuration
            
            if #available(iOS 10.0, *) {
                switch pkAsset.settings.dataUsageSettings.forwardBufferMode {
                case .custom:
                    self.preferredForwardBufferDuration = settingsPreferredForwardBufferDuration
                // for using forward buffer logic always start with the minimum buffer and increase over time.
                case .userEngagement, .duration, .durationCustom:
                    self.preferredForwardBufferDuration = ForwardBufferLogic.minForwardBuffer
                case .none:
                    self.preferredForwardBufferDuration = 0
                }
            } else {
                PKLog.warning("preferred forward buffer was used but it is only supported on iOS 10 and above")
            }
        }
    }
}

@objc public class PKAsset: NSObject {
    let avAsset: AVURLAsset
    let settings: PKAssetSettings
    
    init(avAsset: AVURLAsset, settings: PKAssetSettings) {
        self.avAsset = avAsset
        self.settings = settings
    }
}

/************************************************************/
// MARK: - PKPlayerSettings
/************************************************************/

/// `PKPlayerConfig` object used as default configuration values for players.
@objc public class PKPlayerSettings: NSObject, PKAssetSettings {
    
    /// The settings for network data consumption.
    @objc public var dataUsageSettings = PKDataUsageSettings()
    @objc public var startupMode: PKMediaStartupMode = .normal
    
    @objc public var contentRequestAdapter: PKRequestParamsAdapter? = KalturaPlaybackRequestAdapter()
    
    @objc public func createCopy() -> PKPlayerSettings {
        let copy = PKPlayerSettings()
        copy.dataUsageSettings = self.dataUsageSettings
        copy.startupMode = self.startupMode
        copy.contentRequestAdapter = self.contentRequestAdapter
        return copy
    }
}

extension PKPlayerSettings: NSCopying {
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return self.createCopy()
    }
}
