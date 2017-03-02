//
//  PKError.swift
//  Pods
//
//  Created by Gal Orlanczyk on 19/02/2017.
//
//

import Foundation
import AVFoundation 

/************************************************************/
// MARK: - PlayerError
/************************************************************/

/// `PlayerError` represents player errors.
enum PlayerError: PKError {
    
    case failedToLoadAssetFromKeys(rootError: NSError?)
    case assetNotPlayable
    case failedToPlayToEndTime(rootError: NSError)
    case playerItemErrorLogEvent(errorLogEvent: AVPlayerItemErrorLogEvent)
    
    static let Domain = "com.kaltura.playkit.error.player"
    
    var code: Int {
        switch self {
        case .failedToLoadAssetFromKeys: return PKErrorCode.FailedToLoadAssetFromKeys
        case .assetNotPlayable: return PKErrorCode.AssetNotPlayable
        case .failedToPlayToEndTime: return PKErrorCode.FailedToPlayToEndTime
        case .playerItemErrorLogEvent: return PKErrorCode.PlayerItemErrorLogEvent
        }
    }
    
    var errorDescription: String {
        switch self {
        case .failedToLoadAssetFromKeys: return "Can't use this AVAsset because one of it's keys failed to load"
        case .assetNotPlayable: return "Can't use this AVAsset because it isn't playable"
        case .failedToPlayToEndTime: return "Item failed to play to its end time"
        case .playerItemErrorLogEvent(let errorLogEvent): return errorLogEvent.errorComment ?? ""
        }
    }
    
    var userInfo: [String: Any] {
        switch self {
        case .failedToLoadAssetFromKeys(let rootError):
            if let rError = rootError {
                return [PKErrorKeys.RootErrorKey : rError]
            }
            return [:]
        case .assetNotPlayable: return [:]
        case .failedToPlayToEndTime(let rootError): return [PKErrorKeys.RootErrorKey : rootError]
        case .playerItemErrorLogEvent(let errorLogEvent):
            return [
                PKErrorKeys.RootCodeKey : errorLogEvent.errorStatusCode,
                PKErrorKeys.RootDomainKey : errorLogEvent.errorDomain
            ]
        }
    }
}

/************************************************************/
// MARK: - PKPluginError
/************************************************************/

/// `PKPluginError` represents plugins errors.
enum PKPluginError: PKError {
    
    case failedToCreatePlugin(pluginName: String)
    case missingPluginConfig(pluginName: String)
    
    static let Domain = "com.kaltura.playkit.error.plugins"
    
    var code: Int {
        switch self {
        case .failedToCreatePlugin: return PKErrorCode.FailedToCreatePlugin
        case .missingPluginConfig: return PKErrorCode.MissingPluginConfig
        }
    }
    
    var errorDescription: String {
        switch self {
        case .failedToCreatePlugin(let pluginName): return "failed to create plugin (\(pluginName)), doesn't exist in registry"
        case .missingPluginConfig(let pluginName): return "Missing plugin config for plugin: \(pluginName)"
        }
    }
    
    var userInfo: [String: Any] {
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
protocol PKError: Error, CustomStringConvertible {
    
    /// The error domain (used for creating `NSError`)
    static var Domain: String { get }
    
    /**
     The error code.
     use `switch self` to retrive the value in **enums**.
     
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
    var userInfo: [String : Any] { get }
    
    /// creates an `NSError` from the selected case.
    var asNSError: NSError { get }
}

/************************************************************/
// MARK: - PKError default implementations
/************************************************************/

extension PKError {
    /// description string
    var description: String {
        return "\(type(of: self)) ,domain: \(type(of: self).Domain), errorCode: \(self.code)"
    }
    
    /// creates an `NSError` from the selected case.
    var asNSError: NSError {
        var userInfo = self.userInfo
        userInfo[NSLocalizedDescriptionKey] = self.errorDescription
        return NSError(domain: Self.Domain, code: self.code, userInfo: userInfo)
    }
}

extension PKError where Self: RawRepresentable, Self.RawValue == String {
    var description: String {
        return "\(self.rawValue), domain: \(type(of: self).Domain), errorCode: \(self.code)"
    }
}

/************************************************************/
// MARK: - Error
/************************************************************/
// extension for easier access to domain and code properties.
extension Error {
    
    public var domain: String {
        return self._domain
    }
    
    public var code: Int {
        return self._code
    }
}

/************************************************************/
// MARK: - PKError UserInfo Keys
/************************************************************/

// general userInfo keys.
struct PKErrorKeys {
    static let RootErrorKey = NSUnderlyingErrorKey
    static let RootCodeKey = "rootCode"
    static let RootDomainKey = "rootDomain"
}

/************************************************************/
// MARK: - PlayKit Error Domains
/************************************************************/

@objc public class PKErrorDomain: NSObject {
    @objc public static let Plugin = PKPluginError.Domain
    @objc public static let Player = PlayerError.Domain
}

/************************************************************/
// MARK: - PlayKit Error Codes
/************************************************************/

@objc public class PKErrorCode: NSObject {
    // PlayerError
    @objc public static let FailedToLoadAssetFromKeys = 7000
    @objc public static let AssetNotPlayable = 7001
    @objc public static let FailedToPlayToEndTime = 7002
    @objc public static let PlayerItemErrorLogEvent = 7003
    // PKPluginError
    @objc public static let FailedToCreatePlugin = 2000
    @objc public static let MissingPluginConfig = 2001
}

