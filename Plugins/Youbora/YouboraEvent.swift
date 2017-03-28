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
            self.init(["message": message])
        }
    }
    /// this event notifies when a youbora event is being sent
    @objc public static let report: YouboraEvent.Type = Report.self
    
    @available(*, unavailable, renamed: "report")
    @objc public static let youboraReportSent: YouboraEvent.Type = Report.self
}
