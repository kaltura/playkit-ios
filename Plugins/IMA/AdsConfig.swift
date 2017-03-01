//
//  AdsConfig.swift
//  Pods
//
//  Created by Vadim Kononov on 14/11/2016.
//
//

import Foundation
import GoogleInteractiveMediaAds

@objc public class AdsConfig: NSObject {
    @objc public var language: String = "en"
    @objc public var enableBackgroundPlayback: Bool {
        return true
    }
    @objc public var autoPlayAdBreaks: Bool {
        return false
    }
    @objc public var videoBitrate = kIMAAutodetectBitrate
    @objc public var videoMimeTypes: [Any]?
    @objc public var adTagUrl: String?
    @objc public var tagsTimes: [TimeInterval: String]?
    @objc public var companionView: UIView?
    @objc public var webOpenerPresentingController: UIViewController?

    // Builders
    @discardableResult
    @nonobjc public func set(language: String) -> Self {
        self.language = language
        return self
    }
    
    @discardableResult
    @nonobjc public func set(videoBitrate: Int32) -> Self {
        self.videoBitrate = videoBitrate
        return self
    }
    
    @discardableResult
    @nonobjc public func set(videoMimeTypes: [Any]) -> Self {
        self.videoMimeTypes = videoMimeTypes
        return self
    }
    
    @discardableResult
    @nonobjc public func set(adTagUrl: String) -> Self {
        self.adTagUrl = adTagUrl
        return self
    }
    
    @discardableResult
    @nonobjc public func set(tagsTimes: [TimeInterval: String]) -> Self {
        self.tagsTimes = tagsTimes
        return self
    }
    
    @discardableResult
    @nonobjc public func set(companionView: UIView) -> Self {
        self.companionView = companionView
        return self
    }
    
    @discardableResult
    @nonobjc public func set(webOpenerPresentingController: UIViewController) -> Self {
        self.webOpenerPresentingController = webOpenerPresentingController
        return self
    }
}
