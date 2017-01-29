//
//  PKReachability.swift
//  Pods
//
//  Created by Gal Orlanczyk on 25/01/2017.
//
//

import Foundation
import SystemConfiguration

/************************************************************/
// MARK: - ReachabilityError
/************************************************************/

/// Reachability error
// - important: if needs to change domain/code/description please make sure to update documentation!
enum ReachabilityError: Error {
    /// Network connection is unreachable.
    case unreachable
    case unableToSetCallback
    case unableToSetDispatchQueue
    
    var asNSError: NSError {
        let userInfo = [NSLocalizedDescriptionKey : self.description]
        switch self {
        case .unreachable:
            let error = NSError(domain: ErrorManager.Domain.PlayKitReachability.rawValue, code: self.code, userInfo: userInfo)
            return error
        case .unableToSetCallback: return NSError(domain: ErrorManager.Domain.PlayKitReachability.rawValue, code: self.code, userInfo: nil)
        case .unableToSetDispatchQueue: return NSError(domain: ErrorManager.Domain.PlayKitReachability.rawValue, code: self.code, userInfo: nil)
        }
    }
    
    var code: Int {
        switch self {
        case .unreachable: return 100
        case .unableToSetCallback: return 101
        case .unableToSetDispatchQueue: return 102
        }
    }
    
    var description: String {
        switch self {
        case .unreachable: return "Network connection is unreachable"
        case .unableToSetCallback: return "unable to set reachability callback"
        case .unableToSetDispatchQueue: return "unable to set reachability dispatch queue"
        }
    }
}

/************************************************************/
// MARK: - ReachabilityManager
/************************************************************/

class ReachabilityManager {
    static let shared = ReachabilityManager()
    private init() {}
    
    let reachability = Reachability()
    
    /// counts the amount of objects requested to be notified on changes.
    /// used in order to start actual notifier once for everyone and stop once reaches zero.
    private var count: Int = 0
    
    func startNotifier() throws {
        sync {
            count += 1
        }
        try self.reachability?.startNotifier()
    }
    
    func stopNotifier() {
        sync {
            if count > 0 {
                count -= 1
                if count == 0 {
                    self.reachability?.stopNotifier()
                }
            }
        }
    }
    
    private func sync(block: () -> ()) {
        objc_sync_enter(count)
        block()
        objc_sync_exit(count)
    }
    
    deinit {
        self.reachability?.stopNotifier()
    }
    
    var isReachable: Bool? {
        return self.reachability?.isReachable
    }
    
    var isReachableViaWiFi: Bool? {
        return self.reachability?.isReachableViaWiFi
    }
    
    var isReachableViaWWAN: Bool? {
        return self.reachability?.isReachableViaWWAN
    }
}

/************************************************************/
// MARK: - Reachability
/************************************************************/

extension Notification.Name {
    static let ReachabilityChanged = NSNotification.Name("com.kaltura.playkit.ReachabilityChanged")
}

/// A `Reachability` object offers handling on reachability changed events.
///
/// To observe reachability changes use notification center
/// ````
/// let reachability = notification.object as! Reachability
/// if reachability.isReachable {
///     // reachable!
/// } else {
///     // unreachable!
/// }
/// ````
class Reachability {
    
    typealias ReachabilityHandler = (Reachability) -> Void
    
    fileprivate var reachabilityRef: SCNetworkReachability?
    /// Indicates if notifier is active and listening to network changes.
    fileprivate var notifierRunning = false
    /// Reachability events dispatch queue, used to handle events one by one serially.
    fileprivate let reachabilitySerialDispatchQueue = DispatchQueue(label: "com.kaltura.playkit.reachability")
    fileprivate var previousFlags: SCNetworkReachabilityFlags?
    var reachableOnWWAN: Bool
    
    /// On reachable handler block (single object)
    var onReachable: ReachabilityHandler?
    /// On unreachable handler block (single object)
    var onUnreachable: ReachabilityHandler?
    
    // notifications
    var notificationCenter: NotificationCenter = NotificationCenter.default
    
    fileprivate var isOnDevice: Bool = {
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            return false
        #else
            return true
        #endif
    }()
    
    required init(reachabilityRef: SCNetworkReachability) {
        reachableOnWWAN = true
        self.reachabilityRef = reachabilityRef
    }
    
    convenience init?() {
        var zeroAddress = sockaddr()
        zeroAddress.sa_len = UInt8(MemoryLayout<sockaddr>.size)
        zeroAddress.sa_family = sa_family_t(AF_INET)
        
        guard let ref: SCNetworkReachability = withUnsafePointer(to: &zeroAddress, {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
        }) else { return nil }
        
        self.init(reachabilityRef: ref)
    }
    
    deinit {
        self.stopNotifier()
        self.reachabilityRef = nil
        self.onReachable = nil
        self.onUnreachable = nil
    }
}

func callback(reachability: SCNetworkReachability, flags: SCNetworkReachabilityFlags, info: UnsafeMutableRawPointer?) {
    
    guard let info = info else { return }
    
    let reachability = Unmanaged<Reachability>.fromOpaque(info).takeUnretainedValue()
    
    DispatchQueue.main.async {
        reachability.reachabilityChanged()
    }
}

/************************************************************/
// MARK: - Notifier
/************************************************************/

extension Reachability {
    
    func startNotifier() throws {
        
        guard let reachabilityRef = self.reachabilityRef, !notifierRunning else { return }
        
        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        context.info = UnsafeMutableRawPointer(Unmanaged<Reachability>.passUnretained(self).toOpaque())
        if !SCNetworkReachabilitySetCallback(reachabilityRef, callback, &context) {
            stopNotifier()
            throw ReachabilityError.unableToSetCallback
        }
        
        if !SCNetworkReachabilitySetDispatchQueue(reachabilityRef, reachabilitySerialDispatchQueue) {
            stopNotifier()
            throw ReachabilityError.unableToSetDispatchQueue
        }
        
        // Perform an intial check
        reachabilitySerialDispatchQueue.async {
            self.reachabilityChanged()
        }
        
        self.notifierRunning = true
    }
    
    func stopNotifier() {
        defer { self.notifierRunning = false }
        guard let reachabilityRef = self.reachabilityRef else { return }
        
        SCNetworkReachabilitySetCallback(reachabilityRef, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(reachabilityRef, nil)
    }
}

/************************************************************/
// MARK: - Network Flag Handling
/************************************************************/

extension Reachability {
    
    func reachabilityChanged() {
        let flags = reachabilityFlags
        
        // if same flags as before then nothing has changed...
        guard self.previousFlags != flags else { return }
        
        let block = isReachable ? onReachable : onUnreachable
        block?(self)
        
        self.notificationCenter.post(name: .ReachabilityChanged, object: self)
        
        self.previousFlags = flags
    }
    
    var reachabilityFlags: SCNetworkReachabilityFlags {
        
        guard let reachabilityRef = reachabilityRef else { return SCNetworkReachabilityFlags() }
        
        var flags = SCNetworkReachabilityFlags()
        let gotFlags = withUnsafeMutablePointer(to: &flags) {
            SCNetworkReachabilityGetFlags(reachabilityRef, UnsafeMutablePointer($0))
        }
        
        if gotFlags {
            return flags
        } else {
            return SCNetworkReachabilityFlags()
        }
    }
    
    var isWWANFlagSet: Bool {
        #if os(iOS)
            return self.reachabilityFlags.contains(.isWWAN)
        #else
            return false
        #endif
    }
    
    var isReachableFlagSet: Bool {
        return self.reachabilityFlags.contains(.reachable)
    }
    
    var isConnectionRequiredAndTransientFlagSet: Bool {
        return self.reachabilityFlags.intersection([.connectionRequired, .transientConnection]) == [.connectionRequired, .transientConnection]
    }
}

/************************************************************/
// MARK: - Reachability Testing
/************************************************************/

extension Reachability {
    /// Indicates if we are reachable
    var isReachable: Bool {
        guard isReachableFlagSet else { return false }
        
        if self.isConnectionRequiredAndTransientFlagSet {
            return false
        }
        
        if isOnDevice {
            if self.isWWANFlagSet && !self.reachableOnWWAN {
                return false
            }
        }

        return true
    }
    
    /// Indicates if we are reachable via cellular network.
    var isReachableViaWWAN: Bool {
        // Make sure we are running on device + we are reachable + We are on WWAN
        return self.isOnDevice && self.isReachableFlagSet && self.isWWANFlagSet
    }
    
    /// Indicates if we are reachable via WiFi.
    var isReachableViaWiFi: Bool {
        // Make sure we are reachable
        guard self.isReachableFlagSet else { return false }
        
        // If we're reachable and running on simulator then we are on WiFi
        guard self.isOnDevice else { return true }
        
        // Make sure we are NOT on WWAN
        return !self.isWWANFlagSet
    }
}

