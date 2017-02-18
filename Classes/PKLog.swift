//
//  PKLog.swift
//  Pods
//
//  Created by Eliza Sapir on 27/11/2016.
//
//

import Log

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

public let PKLog: Logger = {
    let logger = Logger()
    logger.minLevel = .trace
    return logger
}()

