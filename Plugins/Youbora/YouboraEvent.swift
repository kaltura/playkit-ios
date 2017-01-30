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
        convenience init(message: NSString) {
            self.init(["message" : message])
        }
    }
    
    public static let youboraReportSent: YouboraEvent.Type = YouboraReportSent.self
}
