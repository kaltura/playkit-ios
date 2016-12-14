//
//  AdsConfig.swift
//  Pods
//
//  Created by Vadim Kononov on 14/11/2016.
//
//

import Foundation

public class AdsConfig {
    public var language: String = "en"
    public var enableBackgroundPlayback: Bool = true
    public var autoPlayAdBreaks: Bool = false
    public var videoBitrate: Int32?
    public var videoMimeTypes: [AnyObject]?
    public var adTagUrl: String?
    public var tagsTimes: [TimeInterval : String]?
    public var companionView: UIView?
    public var webOpenerPresentingController: UIViewController?
    
    public init() {
        
    }
    
    // Builders
    @discardableResult
    public func set(language: String) -> Self {
        self.language = language
        return self
    }
    
    @discardableResult
    public func set(videoBitrate: Int32) -> Self {
        self.videoBitrate = videoBitrate
        return self
    }
    
    @discardableResult
    public func set(videoMimeTypes: [AnyObject]) -> Self {
        self.videoMimeTypes = videoMimeTypes
        return self
    }
    
    @discardableResult
    public func set(adTagUrl: String) -> Self {
        self.adTagUrl = adTagUrl
        return self
    }
    
    @discardableResult
    public func set(tagsTimes: [TimeInterval : String]) -> Self {
        self.tagsTimes = tagsTimes
        return self
    }
    
    @discardableResult
    public func set(companionView: UIView) -> Self {
        self.companionView = companionView
        return self
    }
    
    @discardableResult
    public func set(webOpenerPresentingController: UIViewController) -> Self {
        self.webOpenerPresentingController = webOpenerPresentingController
        return self
    }
}
