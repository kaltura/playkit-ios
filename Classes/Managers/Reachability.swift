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
import SystemConfiguration

/************************************************************/
// MARK: - Reachability
/************************************************************/

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
class PKReachability {
    
    typealias ReachabilityHandler = (PKReachability) -> Void
    
    fileprivate var reachabilityRef: SCNetworkReachability?
    /// Indicates if notifier is active and listening to network changes.
    fileprivate var notifierRunning = false
    /// Reachability events dispatch queue, used to handle events one by one serially.
    fileprivate let reachabilityQueue = DispatchQueue(label: "com.kaltura.playkit.reachability")
    fileprivate var previousFlags: SCNetworkReachabilityFlags?
    var reachableOnWWAN: Bool
    
    /// On reachable handler block (single object)
    var onReachable: ReachabilityHandler?
    /// On unreachable handler block (single object)
    var onUnreachable: ReachabilityHandler?
    
    fileprivate var isOnDevice: Bool = {
        #if targetEnvironment(simulator)
            return false
        #else
            return true
        #endif
    }()
    
    required init(reachabilityRef: SCNetworkReachability) {
        reachableOnWWAN = true
        self.reachabilityRef = reachabilityRef
    }
    
    convenience init?(hostname: String) {
        guard let ref = SCNetworkReachabilityCreateWithName(nil, hostname) else { return nil }
        self.init(reachabilityRef: ref)
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
    
    let reachability = Unmanaged<PKReachability>.fromOpaque(info).takeUnretainedValue()
    
    DispatchQueue.main.async {
        reachability.reachabilityChanged()
    }
}

/************************************************************/
// MARK: - Notifier
/************************************************************/

extension PKReachability {
    
    func startNotifier() {
        
        guard let reachabilityRef = self.reachabilityRef, !notifierRunning else { return }
        
        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        context.info = UnsafeMutableRawPointer(Unmanaged<PKReachability>.passUnretained(self).toOpaque())
        if !SCNetworkReachabilitySetCallback(reachabilityRef, callback, &context) {
            stopNotifier()
        }
        
        if !SCNetworkReachabilitySetDispatchQueue(reachabilityRef, reachabilityQueue) {
            stopNotifier()
        }
        
        // Perform an intial check
        reachabilityQueue.async {
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

extension PKReachability {
    
    func reachabilityChanged() {
        let flags = reachabilityFlags
        
        // if same flags as before then nothing has changed...
        guard self.previousFlags != flags else { return }
        
        let block = isReachable ? onReachable : onUnreachable
        block?(self)
        
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

extension PKReachability {
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
}
