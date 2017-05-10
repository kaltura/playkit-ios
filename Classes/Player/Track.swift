//
//  File.swift
//  Pods
//
//  Created by Eliza Sapir on 05/12/2016.
//
//

import Foundation

@objc public class Track: NSObject {
    @objc public var id: String?
    @objc public var title: String?
    @objc public var language: String?
    
    init(id: String?, title: String?, language: String?) {
        PKLog.debug("init:: id:\(String(describing: id)) title:\(String(describing: title)) language: \(String(describing: language))")
        
        self.id = id
        self.title = title
        self.language = language
    }
}
