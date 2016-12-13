//
//  File.swift
//  Pods
//
//  Created by Eliza Sapir on 05/12/2016.
//
//

import Foundation

public class Track: NSObject {
    public var id: String?
    public var title: String?
    public var language: String?
    
    init(id: String?, title: String?, language: String?) {
        PKLog.debug("init:: id:\(id) title:\(title) language: \(language)")
        
        self.id = id
        self.title = title
        self.language = language
    }
}
