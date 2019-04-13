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
import AVFoundation 

/************************************************************/
// MARK: - PlayerError
/************************************************************/

/// `PlayerError` represents player errors.
enum PlayerError: PKError {
    
    case failedToLoadAssetFromKeys(rootError: NSError?)
    case assetNotPlayable
    case playerItemFailed(rootError: NSError)
    case failed(rootError: NSError)
    
    static let domain = "com.kaltura.playkit.error.player"
    
    var code: Int {
        switch self {
        case .failedToLoadAssetFromKeys: return PKErrorCode.failedToLoadAssetFromKeys
        case .assetNotPlayable: return PKErrorCode.assetNotPlayable
        case .playerItemFailed: return PKErrorCode.playerItemFailed
        case .failed: return PKErrorCode.playerFailed
        }
    }
    
    var errorDescription: String {
        switch self {
        case .failedToLoadAssetFromKeys: return "Can't use this AVAsset because one of its keys failed to load"
        case .assetNotPlayable: return "Can't use this AVAsset because it isn't playable"
        case .playerItemFailed: return "Player item failed to play"
        case .failed: return "Player failed, you can no longer use the player for playback and need to recreate it"
        }
    }
    
    var userInfo: [String: Any] {
        switch self {
        case .failedToLoadAssetFromKeys(let rootError):
            if let rError = rootError {
                return [PKErrorKeys.RootErrorKey: rError]
            }
            return [:]
        case .assetNotPlayable: return [:]
        case .playerItemFailed(let rootError): return [PKErrorKeys.RootErrorKey: rootError]
        case .failed(let rootError): return [PKErrorKeys.RootErrorKey: rootError]
        }
    }
}

/// `PlayerErrorLog` represents an error log emitted from AVPlayer (usually non-fatal).
struct PlayerErrorLog: PKError {
    
    static var domain = PlayerError.domain
    
    let errorLogEvent: AVPlayerItemErrorLogEvent
    
    var code: Int {
        return PKErrorCode.playerItemErrorLogEvent
    }
    
    var errorDescription: String {
        return errorLogEvent.errorComment ?? ""
    }
    
    var userInfo: [String: Any] {
        return [
            PKErrorKeys.RootCodeKey: errorLogEvent.errorStatusCode,
            PKErrorKeys.RootDomainKey: errorLogEvent.errorDomain
        ]
    }
}

/************************************************************/
// MARK: - PKPluginError
/************************************************************/

/// `PKPluginError` represents plugins errors.
public enum PKPluginError: PKError {
    
    case failedToCreatePlugin(pluginName: String)
    case missingPluginConfig(pluginName: String)
    
    public static let domain = "com.kaltura.playkit.error.plugins"
    
    public var code: Int {
        switch self {
        case .failedToCreatePlugin: return PKErrorCode.failedToCreatePlugin
        case .missingPluginConfig: return PKErrorCode.missingPluginConfig
        }
    }
    
    public var errorDescription: String {
        switch self {
        case .failedToCreatePlugin(let pluginName): return "failed to create plugin (\(pluginName)), doesn't exist in registry"
        case .missingPluginConfig(let pluginName): return "Missing plugin config for plugin: \(pluginName) (wrong type or doesn't exist)"
        }
    }
    
    public var userInfo: [String: Any] {
        switch self {
        case .failedToCreatePlugin(let pluginName): return [PKErrorKeys.PluginNameKey: pluginName]
        case .missingPluginConfig(let pluginName): return [PKErrorKeys.PluginNameKey: pluginName]
        }
    }
}

// general plugin error userInfo keys.
extension PKErrorKeys {
    static let PluginNameKey = "pluginName"
}

/************************************************************/
// MARK: - PKError
/************************************************************/

/// `PKError` is used as a protocol for errors that can be converted to `NSError` if need be.
/// - important: should be used on enums for best results on multiple cases!
public protocol PKError: Error, CustomStringConvertible {
    
    /// The error domain (used for creating `NSError`)
    static var domain: String { get }
    
    /**
     The error code.
     use `switch self` to retrieve the value in **enums**.
     
     ````
     var code: Int {
        switch self {
        case .one: return 1
        case .two: return 2
        }
     }
     ````
     */
    var code: Int { get }
    
    /// The error description.
    var errorDescription: String { get }
    
    /**
     Dictionary object to hold all params of the case.
     
     Should take all associated values and create a dictionary for them.
     
     For example in **enum error** when we have 2 cases:
     
     * .one(error: NSError, url: URL)
     * .two(error: NSError))
     
     ````
     var userInfo: [String : Any] {
        switch self {
        case .one(let rootError, let url):
        return ["root": rootError, "url": url]
        case .two(let rootError):
        return ["root": rootError]
        }
     }
     ````
     */
    var userInfo: [String: Any] { get }
    
    /// creates an `NSError` from the selected case.
    var asNSError: NSError { get }
}

/************************************************************/
// MARK: - PKError default implementations
/************************************************************/

public extension PKError {
    /// description string
    var description: String {
        return "\(type(of: self)) ,domain: \(type(of: self).domain), errorCode: \(self.code)"
    }
    
    /// creates an `NSError` from the selected case.
    var asNSError: NSError {
        var userInfo = self.userInfo
        userInfo[NSLocalizedDescriptionKey] = self.errorDescription
        return NSError(domain: Self.domain, code: self.code, userInfo: userInfo)
    }
}

public extension PKError where Self: RawRepresentable, Self.RawValue == String {
    var description: String {
        return "\(self.rawValue), domain: \(type(of: self).domain), errorCode: \(self.code)"
    }
}

/************************************************************/
// MARK: - PKError UserInfo Keys
/************************************************************/

// general userInfo keys.
public struct PKErrorKeys {
    static let RootErrorKey = NSUnderlyingErrorKey
    static let RootCodeKey = "rootCode"
    static let RootDomainKey = "rootDomain"
}

/************************************************************/
// MARK: - PlayKit Error Domains
/************************************************************/

@objc public class PKErrorDomain: NSObject {
    @objc(Plugin) public static let plugin = PKPluginError.domain
    @objc(Player) public static let player = PlayerError.domain
}

/************************************************************/
// MARK: - PlayKit Error Codes
/************************************************************/

@objc public class PKErrorCode: NSObject {
    // PlayerError
    @objc(FailedToLoadAssetFromKeys) public static let failedToLoadAssetFromKeys = 7000
    @objc(AssetNotPlayable) public static let assetNotPlayable = 7001
    @objc(PlayerItemFailed) public static let playerItemFailed = 7002
    @objc(PlayerFailed) public static let playerFailed = 7003
    @objc(MissingDependency) public static let missingDependency = 7004
    // PlayerErrorLog
    @objc(PlayerItemErrorLogEvent) public static let playerItemErrorLogEvent = 7100
    // PKPluginError
    @objc(FailedToCreatePlugin) public static let failedToCreatePlugin = 2000
    @objc(MissingPluginConfig) public static let missingPluginConfig = 2001
}

