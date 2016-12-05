//
//  File.swift
//  Pods
//
//  Created by Eliza Sapir on 05/12/2016.
//
//

import Foundation

public class BaseTrackInfo {
    public var uniqueId: String
    public var title: String
    public var isAdaptive: Bool
    
    init(uniqueId: String, title: String, isAdaptive: Bool) {
        self.uniqueId = uniqueId
        self.title = title
        self.isAdaptive = isAdaptive
    }
}
