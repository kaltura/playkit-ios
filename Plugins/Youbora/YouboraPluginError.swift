//
//  YouboraPluginError.swift
//  Pods
//
//  Created by Gal Orlanczyk on 24/04/2017.
//
//

import Foundation

/// `YouboraPluginError` represents youbora plugin errors.
enum YouboraPluginError: PKError {
    
    case failedToSetupYouboraManager
    
    static let domain = "com.kaltura.playkit.error.youbora"
    
    var code: Int {
        switch self {
        case .failedToSetupYouboraManager: return PKErrorCode.failedToSetupYouboraManager
        }
    }
    
    var errorDescription: String {
        switch self {
        case .failedToSetupYouboraManager: return "failed to setup youbora manager, missing config/config params or mediaEntry"
        }
    }
    
    var userInfo: [String: Any] {
        switch self {
        case .failedToSetupYouboraManager: return [:]
        }
    }
}

extension PKErrorDomain {
    @objc(Youbora) public static let youbora = YouboraPluginError.domain
}

extension PKErrorCode {
    @objc(FailedToSetupYouboraManager) public static let failedToSetupYouboraManager = 2200
}
