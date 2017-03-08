//
//  IMAPluginError.swift
//  Pods
//
//  Created by Gal Orlanczyk on 07/03/2017.
//
//

import Foundation
import GoogleInteractiveMediaAds

/// `IMAPluginError` used to wrap an `IMAAdError` and provide converation to `NSError`
struct IMAPluginError: PKError {
    
    var adError: IMAAdError
    
    static let domain = "com.kaltura.playkit.error.ima"
    
    var code: Int {
        return adError.code.rawValue
    }
    
    var errorDescription: String {
        return adError.message
    }
    
    var userInfo: [String: Any] {
        return [
            PKErrorKeys.ErrorTypeKey: adError.type.rawValue
        ]
    }
}

// IMA plugin error userInfo keys.
extension PKErrorKeys {
    static let ErrorTypeKey = "errorType"
}

extension PKErrorDomain {
    @objc(IMA) public static let ima = IMAPluginError.domain
}
