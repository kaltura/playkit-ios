//
//  File.swift
//  Pods
//
//  Created by Eliza Sapir on 05/12/2016.
//
//

import Foundation

public class Track {
    public var index: Int?
    public var type: String?
    public var title: String?
    public var language: String?
    
    init(index: Int?, type: String?, title: String?, language: String?) {
        PKLog.debug("init:: index:\(index) type:\(type) title:\(title) language: \(language)")
        // TODO:: replace index+type with id
        self.index = index
        self.type = type
        self.title = title
        self.language = language
    }
}
