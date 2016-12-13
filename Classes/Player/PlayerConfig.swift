//
//  PlayerConfig.swift
//  PlayKit
//
//  Created by Noam Tamim on 09/10/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

import Foundation

public class PlayerConfig: NSObject {
    public var mediaEntry : MediaEntry?
    public var startTime : TimeInterval = 0
    public var autoPlay = false
    public var allowPlayerEngineExpose = false
    public var subtitleLanguage: String?
    public var audioLanguage: String?
    public var plugins: [String : AnyObject?]?
    
    // Builders
    @discardableResult
    public func set(mediaEntry: MediaEntry) -> Self {
        self.mediaEntry = mediaEntry
        return self
    }
    
    @discardableResult 
    public func set(autoPlay: Bool) -> Self {
        self.autoPlay = autoPlay
        return self
    }
    
    @discardableResult
    public func set(allowPlayerEngineExpose: Bool) -> Self {
        self.allowPlayerEngineExpose = allowPlayerEngineExpose
        return self
    }
    
    @discardableResult 
    public func set(startTime: TimeInterval) -> Self {
        self.startTime = startTime
        return self
    }
    
    @discardableResult 
    public func set(subtitleLanguage: String) -> Self {
        self.subtitleLanguage = subtitleLanguage
        return self
    } 
    
    @discardableResult 
    public func set(audioLanguage: String) -> Self {
        self.audioLanguage = audioLanguage
        return self
    }
    
    @discardableResult
    public func set(plugins: [String : AnyObject?]) -> Self {
        self.plugins = plugins
        return self
    }
}


