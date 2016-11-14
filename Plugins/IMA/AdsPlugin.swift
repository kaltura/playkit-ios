//
//  AdsPlugin.swift
//  AdvancedExample
//
//  Created by Vadim Kononov on 19/10/2016.
//  Copyright © 2016 Google, Inc. All rights reserved.
//

import GoogleInteractiveMediaAds

@objc enum AdsPluginEventType : Int {
    case ad_break_ready
    case ad_break_ended
    case ad_break_started
    case all_ads_completed
    case clicked
    case complete
    case cuepoints_changed
    case first_quartile
    case loaded
    case log
    case midpoint
    case pause
    case resume
    case skipped
    case started
    case stream_loaded
    case tapped
    case third_quartile
}

@objc protocol AdsPluginDataSource : class {
    @objc optional func adsPluginCanPlayAd(_ adsPlugin: AdsPlugin) -> Bool
}

@objc protocol AdsPluginDelegate : class {
    @objc optional func adsPlugin(_ adsPlugin: AdsPlugin, failedWith error: String)
    @objc optional func adsPlugin(_ adsPlugin: AdsPlugin, didReceive adEvent: AdsPluginEventType)
    @objc optional func adsPluginDidRequestContentResume(_ adsPlugin: AdsPlugin)
    @objc optional func adsPluginDidRequestContentPause(_ adsPlugin: AdsPlugin)
    @objc optional func adsPlugin(_ adsPlugin: AdsPlugin, adDidProgressToTime mediaTime: TimeInterval, totalTime: TimeInterval)
    
    @objc optional func adsPlugin(_ adsPlugin: AdsPlugin, webOpenerWillOpenExternalBrowser webOpener: NSObject!)
    @objc optional func adsPlugin(_ adsPlugin: AdsPlugin, webOpenerWillOpenInAppBrowser webOpener: NSObject!)
    @objc optional func adsPlugin(_ adsPlugin: AdsPlugin, webOpenerDidOpenInAppBrowser webOpener: NSObject!)
    @objc optional func adsPlugin(_ adsPlugin: AdsPlugin, webOpenerWillCloseInAppBrowser webOpener: NSObject!)
    @objc optional func adsPlugin(_ adsPlugin: AdsPlugin, webOpenerDidCloseInAppBrowser webOpener: NSObject!)
}

public class AdsPlugin: NSObject, AVPictureInPictureControllerDelegate, Plugin, DecoratedPlayerProvider, IMAAdsLoaderDelegate, IMAAdsManagerDelegate, IMAWebOpenerDelegate, IMAContentPlayhead {

    private var player: Player!
    
    weak var dataSource: AdsPluginDataSource! {
        didSet {
            self.setupMainView()
        }
    }
    weak var delegate: AdsPluginDelegate?
    weak var pipDelegate: AVPictureInPictureControllerDelegate?
    
    private var contentPlayhead: IMAAVPlayerContentPlayhead?
    private var adsManager: IMAAdsManager?
    private var companionSlot: IMACompanionAdSlot?
    private var adsRenderingSettings: IMAAdsRenderingSettings! = IMAAdsRenderingSettings()
    private static var adsLoader: IMAAdsLoader!
    
    private var pictureInPictureProxy: IMAPictureInPictureProxy?
    private var loadingView: UIView?
    
    private var config: AdsConfig!
    private var adTagUrl: String?
    private var tagsTimes: [TimeInterval : String]? {
        didSet {
            sortedTagsTimes = tagsTimes!.keys.sorted()
        }
    }
    private var sortedTagsTimes: [TimeInterval]?
    
    private var currentPlaybackTime: TimeInterval! = 0 //in seconds
    private var isAdPlayback = false
    private var startAdCalled = false
    
    public var currentTime: TimeInterval {
        get {
            return self.currentPlaybackTime
        }
    }
    
    override public required init() {
        
    }
    
    //MARK: plugin protocol methods
    
    public static var pluginName: String {
        get {
            return String(describing: AdsPlugin.self)
        }
    }
    
    public func load(player: Player, config: Any?) {
        if let adsConfig = config as? AdsConfig {
            self.config = adsConfig
            self.player = player
            
            if AdsPlugin.adsLoader == nil {
                self.setupAdsLoader(with: self.config)
            }
            
            AdsPlugin.adsLoader.contentComplete()
            AdsPlugin.adsLoader.delegate = self
            
            if let adTagUrl = self.config.adTagUrl {
                self.adTagUrl = adTagUrl
            } else if let adTagsTimes = self.config.tagsTimes {
                self.tagsTimes = adTagsTimes
            }
        }
        
        Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(AdsPlugin.update), userInfo: nil, repeats: true)
    }

    public func destroy() {
        self.destroyManager()
    }

    //MARK: DecoratedPlayerProvider protocol methods
    
    func getDecoratedPlayer() -> PlayerDecoratorBase? {
        let decorator = AdsEnabledPlayerController()
        decorator.adsPlugin = self
        return decorator
    }
    
    //MARK: public methods
    
    func requestAds() {
        if self.adTagUrl != nil && self.adTagUrl != "" {
            self.startAdCalled = false
            
            var request: IMAAdsRequest
            
            if let avPlayer = self.player.playerEngine as? AVPlayer {
                request = IMAAdsRequest(adTagUrl: self.adTagUrl, adDisplayContainer: self.createAdDisplayContainer(), avPlayerVideoDisplay: IMAAVPlayerVideoDisplay(avPlayer: avPlayer), pictureInPictureProxy: self.pictureInPictureProxy, userContext: nil)
            } else {
                request = IMAAdsRequest(adTagUrl: self.adTagUrl, adDisplayContainer: self.createAdDisplayContainer(), contentPlayhead: self, userContext: nil)
            }
            
            AdsPlugin.adsLoader.requestAds(with: request)
        }
    }
    
    func start(showLoadingView: Bool) -> Bool {
        if self.adTagUrl != nil && self.adTagUrl != "" {
            if showLoadingView {
                self.showLoadingView(true, alpha: 1)
            }
            
            if let manager = self.adsManager {
                manager.initialize(with: self.adsRenderingSettings)
            } else {
                self.startAdCalled = true
            }
            return true
        }
        return false
    }
    
    func resume() {
        self.adsManager?.resume()
    }
    
    func pause() {
        self.adsManager?.pause()
    }
    
    func contentComplete() {
        AdsPlugin.adsLoader.contentComplete()
    }
    
    //MARK: private methods
    
    private func setupAdsLoader(with config: AdsConfig) {
        let imaSettings: IMASettings! = IMASettings()
        imaSettings.language = config.language
        imaSettings.enableBackgroundPlayback = config.enableBackgroundPlayback
        imaSettings.autoPlayAdBreaks = config.autoPlayAdBreaks
        
        AdsPlugin.adsLoader = IMAAdsLoader(settings: imaSettings)
    }

    private func setupMainView() {
        if let _ = self.player.playerEngine {
            self.pictureInPictureProxy = IMAPictureInPictureProxy(avPictureInPictureControllerDelegate: self)
        }
        
        if (self.config.companionView != nil) {
            self.companionSlot = IMACompanionAdSlot(view: self.config.companionView, width: Int32(self.config.companionView!.frame.size.width), height: Int32(self.config.companionView!.frame.size.height))
        }
    }
    
    private func setupLoadingView() {
        self.loadingView = UIView(frame: CGRect.zero)
        self.loadingView!.translatesAutoresizingMaskIntoConstraints = false
        self.loadingView!.backgroundColor = UIColor.black
        self.loadingView!.isHidden = true
        
        let indicator = UIActivityIndicatorView()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        indicator.startAnimating()
        
        self.loadingView!.addSubview(indicator)
        self.loadingView!.addConstraint(NSLayoutConstraint(item: self.loadingView!, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: indicator, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0))
        self.loadingView!.addConstraint(NSLayoutConstraint(item: self.loadingView!, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: indicator, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0))
        
        let videoView = self.player.view
        videoView?.addSubview(self.loadingView!)
        videoView?.addConstraint(NSLayoutConstraint(item: videoView!, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self.loadingView!, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0))
        videoView?.addConstraint(NSLayoutConstraint(item: videoView!, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: self.loadingView!, attribute: NSLayoutAttribute.left, multiplier: 1, constant: 0))
        videoView?.addConstraint(NSLayoutConstraint(item: videoView!, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self.loadingView!, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: 0))
        videoView?.addConstraint(NSLayoutConstraint(item: videoView!, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: self.loadingView!, attribute: NSLayoutAttribute.right, multiplier: 1, constant: 0))
    }
    
    private func createAdDisplayContainer() -> IMAAdDisplayContainer {
        return IMAAdDisplayContainer(adContainer: self.player.view, companionSlots: self.config.companionView != nil ? [self.companionSlot!] : nil)
    }

    private func loadAdsIfNeeded() {
        if self.tagsTimes != nil {
            let key = floor(self.currentPlaybackTime)
            if self.sortedTagsTimes!.count > 0 && key >= self.sortedTagsTimes![0] {
                if let adTag = self.tagsTimes![key] {
                    self.updateAdTag(adTag, tagTimeKeyForRemove: key)
                } else {
                    let closestKey = self.findClosestTimeInterval(for: key)
                    let adTag = self.tagsTimes![closestKey]
                    self.updateAdTag(adTag!, tagTimeKeyForRemove: closestKey)
                }
            }
        }
    }
    
    private func updateAdTag(_ adTag: String, tagTimeKeyForRemove: TimeInterval) {
        self.tagsTimes![tagTimeKeyForRemove] = nil
        self.destroyManager()
        
        self.adTagUrl = adTag
        self.requestAds()
        self.start(showLoadingView: false)
    }
    
    private func findClosestTimeInterval(for searchItem: TimeInterval) -> TimeInterval {
        var result = self.sortedTagsTimes![0]
        for item in self.sortedTagsTimes! {
            if item > searchItem {
                break
            }
            result = item
        }
        return result
    }
    
    @objc private func update() {
        if !self.isAdPlayback {
            self.currentPlaybackTime = self.player.currentTime
            self.loadAdsIfNeeded()
        }
    }
    
    private func createRenderingSettings() {
        self.adsRenderingSettings.webOpenerDelegate = self
        if let webOpenerPresentingController = self.config.webOpenerPresentingController {
            self.adsRenderingSettings.webOpenerPresentingController = webOpenerPresentingController
        }
        
        if let bitrate = self.config.videoBitrate {
            self.adsRenderingSettings.bitrate = bitrate
        }
        if let mimeTypes = self.config.videoMimeTypes {
            self.adsRenderingSettings.mimeTypes = mimeTypes
        }
    }
    
    private func showLoadingView(_ show: Bool, alpha: CGFloat) {
        if self.loadingView == nil {
            self.setupLoadingView()
        }
        
        self.loadingView!.alpha = alpha
        self.loadingView!.isHidden = !show

        self.player.view?.bringSubview(toFront: self.loadingView!)
    }
    
    private func resumeContentPlayback() {
        self.showLoadingView(false, alpha: 0)
        self.player.play()
    }
    
    private func destroyManager() {
        self.adsManager?.destroy()
        self.adsManager = nil
    }
    
    // MARK: AdsLoaderDelegate
    
    public func adsLoader(_ loader: IMAAdsLoader!, adsLoadedWith adsLoadedData: IMAAdsLoadedData!) {
        self.adsManager = adsLoadedData.adsManager
        self.adsManager!.delegate = self
        self.createRenderingSettings()
        
        if self.startAdCalled {
            self.adsManager!.initialize(with: self.adsRenderingSettings)
        }
    }
    
    public func adsLoader(_ loader: IMAAdsLoader!, failedWith adErrorData: IMAAdLoadingErrorData!) {
        print(adErrorData.adError.message)
        self.delegate?.adsPlugin?(self, failedWith: adErrorData.adError.message)
        self.resumeContentPlayback()
    }
    
    // MARK: AdsManagerDelegate
    
    public func adsManagerAdDidStartBuffering(_ adsManager: IMAAdsManager!) {
        self.showLoadingView(true, alpha: 0.1)
    }
    
    public func adsManagerAdPlaybackReady(_ adsManager: IMAAdsManager!) {
        self.showLoadingView(false, alpha: 0)
    }
    
    public func adsManager(_ adsManager: IMAAdsManager!, didReceive event: IMAAdEvent!) {
        if event.type == IMAAdEventType.AD_BREAK_READY || event.type == IMAAdEventType.LOADED {
            let canPlay = self.dataSource.adsPluginCanPlayAd?(self)
            if canPlay == nil || canPlay == true {
                adsManager.start()
            } else {
                if event.type == IMAAdEventType.LOADED {
                    adsManager.skip()
                }
            }
        } else if event.type == IMAAdEventType.AD_BREAK_STARTED || event.type == IMAAdEventType.STARTED {
            self.showLoadingView(false, alpha: 0)
        }
        self.delegate?.adsPlugin?(self, didReceive: AdsPluginEventType(rawValue: event.type.rawValue)!)
    }
    
    public func adsManager(_ adsManager: IMAAdsManager!, didReceive error: IMAAdError!) {
        self.delegate?.adsPlugin?(self, failedWith: error.message)
        self.resumeContentPlayback()
    }
    
    public func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager!) {
        self.delegate?.adsPluginDidRequestContentPause?(self)
        self.isAdPlayback = true
        self.player.pause()
    }
    
    public func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager!) {
        self.delegate?.adsPluginDidRequestContentResume?(self)
        self.isAdPlayback = false
        self.resumeContentPlayback()
    }
    
    public func adsManager(_ adsManager: IMAAdsManager!, adDidProgressToTime mediaTime: TimeInterval, totalTime: TimeInterval) {
        if self.player.playerEngine == nil {
            self.delegate?.adsPlugin?(self, adDidProgressToTime: mediaTime, totalTime: totalTime)
        }
    }
    
    // MARK: AVPictureInPictureControllerDelegate
    
    @available(iOS 9.0, *)
    public func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        self.pipDelegate?.pictureInPictureControllerWillStartPictureInPicture?(pictureInPictureController)
    }
    
    @available(iOS 9.0, *)
    public func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        self.pipDelegate?.pictureInPictureControllerDidStartPictureInPicture?(pictureInPictureController)
    }
    
    @available(iOS 9.0, *)
    public func picture(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        self.pipDelegate?.picture?(pictureInPictureController, failedToStartPictureInPictureWithError: error)
    }
    
    @available(iOS 9.0, *)
    public func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        self.pipDelegate?.pictureInPictureControllerWillStopPictureInPicture?(pictureInPictureController)
    }
    
    @available(iOS 9.0, *)
    public func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        self.pipDelegate?.pictureInPictureControllerDidStopPictureInPicture?(pictureInPictureController)
    }
    
    @available(iOS 9.0, *)
    public func picture(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        self.pipDelegate?.picture?(pictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler: completionHandler)
    }

    // MARK: IMAWebOpenerDelegate
    
    public func webOpenerWillOpenExternalBrowser(_ webOpener: NSObject!) {
        self.delegate?.adsPlugin?(self, webOpenerWillOpenExternalBrowser: webOpener)
    }
    
    public func webOpenerWillOpen(inAppBrowser webOpener: NSObject!) {
        self.delegate?.adsPlugin?(self, webOpenerWillOpenInAppBrowser: webOpener)
    }
    
    public func webOpenerDidOpen(inAppBrowser webOpener: NSObject!) {
        self.delegate?.adsPlugin?(self, webOpenerDidOpenInAppBrowser: webOpener)
    }
    
    public func webOpenerWillClose(inAppBrowser webOpener: NSObject!) {
        self.delegate?.adsPlugin?(self, webOpenerWillCloseInAppBrowser: webOpener)
    }
    
    public func webOpenerDidClose(inAppBrowser webOpener: NSObject!) {
        self.delegate?.adsPlugin?(self, webOpenerDidCloseInAppBrowser: webOpener)
    }
}
