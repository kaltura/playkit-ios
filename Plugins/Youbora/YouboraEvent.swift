//
//  YouboraEvent.swift
//  Pods
//
//  Created by Oded Klein on 05/12/2016.
//
//

import UIKit

public class YouboraReportSent : PKEvent {
    public let message: String
    public init(message: String) {
        self.message = message
    }
}
