//
//  AudioTrackInfo.swift
//  Pods
//
//  Created by Eliza Sapir on 05/12/2016.
//
//

import Foundation

public class AudioTrackInfo: BaseTrackInfo {
    public var language: String;
    
    init(uniqueId: String, title:String, isAdaptive: Bool, language: String) {
        self.language = language
        super.init(uniqueId: uniqueId, title: title, isAdaptive: isAdaptive)
    }
}
