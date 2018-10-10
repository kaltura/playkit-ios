// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import XCGLogger

/**
 # property PKLog
 
 ## abstract
 
 Logging framework that provides built-in themes and formatters.
 
 
 ## level
 
 Define a minimum level of severity to only print the messages with a greater or equal severity:
 
     PKLog.minLevel = .warning
 
 
 ## disable
 
 Disable Log by setting enabled to false:
 
     PKLog.enabled = false
 
 
 ## use

     PKLog.trace("Called!!!")
     PKLog.debug("Who is self:", self)
     PKLog.info(some, objects, here)
     PKLog.warning(one, two, three, separator: " - ")
     PKLog.error(error, terminator: "\n")
 */

/// `PKLogLevel` describes the available log levels.
@objc public enum PKLogLevel: Int {
    case verbose, debug, info, warning, error
    
    static let `default` = PKLogLevel.debug
    
    var description: String {
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

    

extension XCGLogger {
    func trace(_ closure: @autoclosure () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:]) {
        self.logln(.verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: closure)
    }
}
