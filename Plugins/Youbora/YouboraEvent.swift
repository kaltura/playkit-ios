//
//  YouboraEvent.swift
//  Pods
//
//  Created by Oded Klein on 05/12/2016.
//
//

import UIKit

public class YouboraEvent: PKEvent {
    class YouboraReportSent : YouboraEvent {
        init(message: NSString) {
            super.init(["message" : message])
        }
    }
    
    @objc public static let youboraReportSent: YouboraEvent.Type = YouboraReportSent.self
}
