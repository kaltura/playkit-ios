//
//  YouboraEvent.swift
//  Pods
//
//  Created by Oded Klein on 05/12/2016.
//
//

import UIKit

@objc public class YouboraEvent: PKEvent {
    
    class Report: YouboraEvent {
        convenience init(message: String) {
            self.init([YouboraEvent.messageKey: message])
        }
    }
    
    /// this event notifies when a youbora event is being sent
    @objc public static let report: YouboraEvent.Type = Report.self
    
    @objc public static let messageKey = "message"
}

extension PKEvent {
    /// Report Value, PKEvent Data Accessor
    @objc public var youboraMessage: String? {
        return self.data?[YouboraEvent.messageKey] as? String
    }
}
