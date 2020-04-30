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
import XCGLogger

/// `PKLogLevel` describes the available log levels.
@objc public enum PKLogLevel: Int, CustomStringConvertible {
    case verbose, debug, info, warning, error
    
    static let `default` = PKLogLevel.debug
    
    public var description: String {
        return String(describing: self).uppercased()
    }
    
    /// converts our levels to the levels of logger we wrap
    var toLoggerLevel: XCGLogger.Level {
        switch self {
        case .verbose: return .verbose
        case .debug: return .debug
        case .info: return .info
        case .warning: return .warning
        case .error: return .error
        }
    }
}

public let PKLog: XCGLogger = {
    let logger = XCGLogger(identifier: "PlayKit")
    logger.outputLevel = PKLogLevel.default.toLoggerLevel
    return logger
}()

// For compatibility with the old logger -- in XCGLogger 'trace' is called 'verbose'.
public extension XCGLogger {
    func trace(_ closure: @autoclosure () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:]) {
        self.logln(.verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: closure)
    }
}
