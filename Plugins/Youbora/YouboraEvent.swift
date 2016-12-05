//
//  YouboraEvent.swift
//  Pods
//
//  Created by Oded Klein on 05/12/2016.
//
//

import UIKit

public class YouboraReportSent : PKEvent {
    public let source: String       // Source of the log, for example PKPlugin.pluginName
    public let message: String
    public var params: [String: Any]?
    public init(source: String, message: String) {
        self.source = source
        self.message = message
    }
}
