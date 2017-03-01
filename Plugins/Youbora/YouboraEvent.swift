//
//  YouboraEvent.swift
//  Pods
//
//  Created by Oded Klein on 05/12/2016.
//
//

import UIKit

@objc public class YouboraEvent: PKEvent {
    
    class YouboraReportSent : YouboraEvent {
        convenience init(message: NSString) {
            self.init(["message" : message])
        }
    }
    
    @objc public static let youboraReportSent: YouboraEvent.Type = YouboraReportSent.self
}
