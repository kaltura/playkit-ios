//
//  PKError.swift
//  Pods
//
//  Created by Gal Orlanczyk on 19/02/2017.
//
//

import Foundation

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
// MARK: - PKError UserInfo Keys
/************************************************************/

// general userInfo keys.
extension PKError {
    var RootErrorKey: String {
        return "rootError"
    }
    
    var RootCodeKey: String {
        return "rootCode"
    }
    
    var RootDomainKey: String {
        return "rootDomain"
    }
}

// general plugin error userInfo keys.
extension PKPluginError  {
    var PluginNameKey: String {
        return "pluginName"
    }
}

/************************************************************/
// MARK: - PlayKit Error Domains
/************************************************************/

@objc public class PKErrorDomain: NSObject { // public interface
    public static let IMA = "com.kaltura.playkit.error.ima"
    public static let Plugin = "com.kaltura.playkit.error.plugins"
    public static let Player = "com.kaltura.playkit.error.player"
    public static let Youbora = "com.kaltura.playkit.error.youbora"
    public static let AnalyticsPlugin = "com.kaltura.playkit.error.analyticsPlugin"
}

