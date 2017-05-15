//
//  AdsConfig.swift
//  Pods
//
//  Created by Vadim Kononov on 14/11/2016.
//
//

import Foundation
import GoogleInteractiveMediaAds

@objc public class IMAConfig: NSObject {
    
    @objc public let enableBackgroundPlayback = true
    // defaulted to false, because otherwise ad breaks events will not happen.
    // we need to have control on whether ad break will start playing or not using `Loaded` event is not enough. 
    // (will also need more safety checks for loaded because loaded will happen more than once).
    @objc public let autoPlayAdBreaks = false
    @objc public var language: String = "en"

    @objc public var videoBitrate = kIMAAutodetectBitrate
    @objc public var videoMimeTypes: [Any]?
    @objc public var adTagUrl: String = ""
    @objc public var companionView: UIView?
    @objc public var webOpenerPresentingController: UIViewController?
    /// ads request timeout interval, when ads request will take more then this time will resume content.
    @objc public var requestTimeoutInterval: TimeInterval = IMAPlugin.defaultTimeoutInterval
    /// enables debug mode on IMA SDK which will output detailed log information to the console. 
    /// The default value is false.
    @objc public var enableDebugMode: Bool = false
    
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
    @nonobjc public func set(companionView: UIView) -> Self {
        self.companionView = companionView
        return self
    }
    
    @discardableResult
    @nonobjc public func set(webOpenerPresentingController: UIViewController) -> Self {
        self.webOpenerPresentingController = webOpenerPresentingController
        return self
    }
    
    @discardableResult
    @nonobjc public func set(requestTimeoutInterval: TimeInterval) -> Self {
        self.requestTimeoutInterval = requestTimeoutInterval
        return self
    }
}
