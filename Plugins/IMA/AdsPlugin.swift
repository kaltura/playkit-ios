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
    func adsPluginVideoView(_ adsPlugin: AdsPlugin) -> UIView
    
    @objc optional func adsPluginCanPlayAd(_ adsPlugin: AdsPlugin) -> Bool
    @objc optional func adsPluginCompanionView(_ adsPlugin: AdsPlugin) -> UIView?
    @objc optional func adsPluginVideoBitrate(_ adsPlugin: AdsPlugin) -> Int32
    @objc optional func adsPluginVideoMimeTypes(_ adsPlugin: AdsPlugin) -> [AnyObject]
    @objc optional func adsPluginWebOpenerPresentingController(_ adsPlugin: AdsPlugin) -> UIViewController?
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

class AdsPluginSettings {
    var language: String = "en"
    var enableBackgroundPlayback: Bool = true
    var autoPlayAdBreaks: Bool = false
    
    init() {
        
    }
    
    init(language: String, enableBackgroundPlayback: Bool, autoPlayAdBreaks: Bool) {
        self.language = language
        self.enableBackgroundPlayback = enableBackgroundPlayback
        self.autoPlayAdBreaks = autoPlayAdBreaks
    }
}

class AdsPlugin: NSObject, AVPictureInPictureControllerDelegate, Plugin, DecoratedPlayerProvider, IMAAdsLoaderDelegate, IMAAdsManagerDelegate, IMAWebOpenerDelegate, IMAContentPlayhead {

    private var player: Player!
    private var config: AnyObject?
    
    public weak var dataSource: AdsPluginDataSource! {
        didSet {
            self.setupMainView()
        }
    }
    public weak var delegate: AdsPluginDelegate?
    public weak var pipDelegate: AVPictureInPictureControllerDelegate?
    
    private var contentPlayhead: IMAAVPlayerContentPlayhead?
    private var adsManager: IMAAdsManager?
    private var companionSlot: IMACompanionAdSlot?
    private var adsRenderingSettings: IMAAdsRenderingSettings! = IMAAdsRenderingSettings()
    private static var adsLoader: IMAAdsLoader!
    
    private var pictureInPictureProxy: IMAPictureInPictureProxy?

    private var companionView: UIView?
    private var videoView: UIView?
    private var loadingView: UIView?
    
    public var tagsTimes: [TimeInterval : String]? {
        didSet {
            sortedTagsTimes = tagsTimes!.keys.sorted()
        }
    }
    private var sortedTagsTimes: [TimeInterval]?
    
    private var currentPlaybackTime: TimeInterval! = 0 //in seconds
    private var isAdPlayback = false
    private var startAdCalled = false
    
    
    override init() {
        super.init()
        
        if AdsPlugin.adsLoader == nil {
            self.setupAdsLoader(with: AdsPluginSettings(language: "en", enableBackgroundPlayback: true, autoPlayAdBreaks: false))
        }
        
        AdsPlugin.adsLoader.contentComplete()
        AdsPlugin.adsLoader.delegate = self
    }
    
    var currentTime: TimeInterval {
        get {
            return self.currentPlaybackTime
        }
    }
    
    //MARK: public methods
    
    func load(player: Player, config: AnyObject?) {
        self.player = player
        self.config = config
        
        self.player.subscribe(to: PlayerEventType.playhead_state_changed, using: { (eventData: AnyObject?) -> Void in
            self.update(with: (eventData as! KalturaPlayerEventData).currentTime)
        })
    }
    
    func getDecoratedPlayer() -> Player {
        let decorator = AdsEnabledPlayerController()
        decorator.adsPlugin = self
        decorator.player = self.player
        
        if self.config != nil {
            if let adTagUrl = self.config as? String {
                decorator.adTagUrl = adTagUrl
            } else if let adTagsTimes = self.config as? [TimeInterval : String] {
                decorator.adTagsTimes = adTagsTimes
            }
        }
        
        self.delegate = decorator
        return decorator
    }
    
    func requestAds(with adTagUrl: String) {
        self.startAdCalled = false
        
        var request: IMAAdsRequest
        
        if let avPlayer = self.player.avPlayer {
            request = IMAAdsRequest(adTagUrl: adTagUrl, adDisplayContainer: self.createAdDisplayContainer(), avPlayerVideoDisplay: IMAAVPlayerVideoDisplay(avPlayer: avPlayer), pictureInPictureProxy: self.pictureInPictureProxy, userContext: nil)
        } else {
            request = IMAAdsRequest(adTagUrl: adTagUrl, adDisplayContainer: self.createAdDisplayContainer(), contentPlayhead: self, userContext: nil)
        }
        
        AdsPlugin.adsLoader.requestAds(with: request)
    }
    
    func start(showLoadingView: Bool) {
        if showLoadingView {
            self.showLoadingView(true, alpha: 1)
        }
        
        if let manager = self.adsManager {
            manager.initialize(with: self.adsRenderingSettings)
        } else {
            self.startAdCalled = true
        }
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
    
    func destroy() {
        self.destroyManager()
    }

    //MARK: private methods
    
    private func setupAdsLoader(with settings: AdsPluginSettings) {
        let imaSettings: IMASettings! = IMASettings()
        imaSettings.language = settings.language
        imaSettings.enableBackgroundPlayback = settings.enableBackgroundPlayback
        imaSettings.autoPlayAdBreaks = settings.autoPlayAdBreaks
        
        AdsPlugin.adsLoader = IMAAdsLoader(settings: imaSettings)
    }

    private func setupMainView() {
        self.companionView = self.dataSource.adsPluginCompanionView?(self)
        self.videoView = self.dataSource.adsPluginVideoView(self)
        
        if let _ = self.player.avPlayer {
            self.pictureInPictureProxy = IMAPictureInPictureProxy(avPictureInPictureControllerDelegate: self)
        }
        
        if (self.companionView != nil) {
            self.companionSlot = IMACompanionAdSlot(view: self.companionView, width: Int32(self.companionView!.frame.size.width), height: Int32(self.companionView!.frame.size.height))
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
        
        videoView?.addSubview(self.loadingView!)
        videoView?.addConstraint(NSLayoutConstraint(item: videoView!, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self.loadingView!, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0))
        videoView?.addConstraint(NSLayoutConstraint(item: videoView!, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: self.loadingView!, attribute: NSLayoutAttribute.left, multiplier: 1, constant: 0))
        videoView?.addConstraint(NSLayoutConstraint(item: videoView!, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self.loadingView!, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: 0))
        videoView?.addConstraint(NSLayoutConstraint(item: videoView!, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: self.loadingView!, attribute: NSLayoutAttribute.right, multiplier: 1, constant: 0))
    }
    
    private func createAdDisplayContainer() -> IMAAdDisplayContainer {
        return IMAAdDisplayContainer(adContainer: self.dataSource.adsPluginVideoView(self), companionSlots: self.companionView != nil ? [self.companionSlot!] : nil)
    }

    private func loadAdsIfNeeded() {
        if self.tagsTimes != nil {
            let key = floor(self.currentPlaybackTime)
            if self.sortedTagsTimes!.count > 0 && key >= self.sortedTagsTimes![0] {
                if let adTag = self.tagsTimes![key] {
                    self.tagsTimes![key] = nil
                    self.destroyManager()
                    self.requestAds(with: adTag)
                    self.start(showLoadingView: false)
                } else {
                    let closestKey = self.findClosestTimeInterval(for: key)
                    let adTag = self.tagsTimes![closestKey]
                    self.tagsTimes![closestKey] = nil
                    self.destroyManager()
                    self.requestAds(with: adTag!)
                    self.start(showLoadingView: false)
                }
            }
        }
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
    
    private func update(with currentTime: CMTime) {
        if !self.isAdPlayback {
            self.currentPlaybackTime = CMTimeGetSeconds(currentTime)
            self.loadAdsIfNeeded()
        }
    }
    
    private func createRenderingSettings() {
        self.adsRenderingSettings.webOpenerDelegate = self
        if let webOpenerPresentingController = self.dataSource.adsPluginWebOpenerPresentingController?(self) {
            self.adsRenderingSettings.webOpenerPresentingController = webOpenerPresentingController
        }
        
        if let bitrate = self.dataSource.adsPluginVideoBitrate?(self) {
            self.adsRenderingSettings.bitrate = bitrate
        }
        if let mimeTypes = self.dataSource.adsPluginVideoMimeTypes?(self) {
            self.adsRenderingSettings.mimeTypes = mimeTypes
        }
    }
    
    private func showLoadingView(_ show: Bool, alpha: CGFloat) {
        if self.loadingView == nil {
            self.setupLoadingView()
        }
        
        self.loadingView!.alpha = alpha
        self.loadingView!.isHidden = !show

        self.videoView?.bringSubview(toFront: self.loadingView!)
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
    
    func adsLoader(_ loader: IMAAdsLoader!, adsLoadedWith adsLoadedData: IMAAdsLoadedData!) {
        self.adsManager = adsLoadedData.adsManager
        self.adsManager!.delegate = self
        self.createRenderingSettings()
        
        if self.startAdCalled {
            self.adsManager!.initialize(with: self.adsRenderingSettings)
        }
    }
    
    func adsLoader(_ loader: IMAAdsLoader!, failedWith adErrorData: IMAAdLoadingErrorData!) {
        self.delegate?.adsPlugin?(self, failedWith: adErrorData.adError.message)
        self.resumeContentPlayback()
    }
    
    // MARK: AdsManagerDelegate
    
    func adsManagerAdDidStartBuffering(_ adsManager: IMAAdsManager!) {
        self.showLoadingView(true, alpha: 0.1)
    }
    
    func adsManagerAdPlaybackReady(_ adsManager: IMAAdsManager!) {
        self.showLoadingView(false, alpha: 0)
    }
    
    func adsManager(_ adsManager: IMAAdsManager!, didReceive event: IMAAdEvent!) {
        if event.type == IMAAdEventType.AD_BREAK_READY || event.type == IMAAdEventType.LOADED {
            let canPlay = self.dataSource.adsPluginCanPlayAd?(self)
            if (canPlay == nil || canPlay == true || self.player.avPlayer != nil) {
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
    
    func adsManager(_ adsManager: IMAAdsManager!, didReceive error: IMAAdError!) {
        self.delegate?.adsPlugin?(self, failedWith: error.message)
        self.resumeContentPlayback()
    }
    
    func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager!) {
        self.delegate?.adsPluginDidRequestContentPause?(self)
        self.isAdPlayback = true
        self.player.pause()
    }
    
    func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager!) {
        self.delegate?.adsPluginDidRequestContentResume?(self)
        self.isAdPlayback = false
        self.resumeContentPlayback()
    }
    
    func adsManager(_ adsManager: IMAAdsManager!, adDidProgressToTime mediaTime: TimeInterval, totalTime: TimeInterval) {
        if self.player.avPlayer == nil {
            self.delegate?.adsPlugin?(self, adDidProgressToTime: mediaTime, totalTime: totalTime)
        }
    }
    
    // MARK: AVPictureInPictureControllerDelegate
    
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        self.pipDelegate?.pictureInPictureControllerWillStartPictureInPicture?(pictureInPictureController)
    }
    
    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        self.pipDelegate?.pictureInPictureControllerDidStartPictureInPicture?(pictureInPictureController)
    }
    
    func picture(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        self.pipDelegate?.picture?(pictureInPictureController, failedToStartPictureInPictureWithError: error)
    }
    
    func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        self.pipDelegate?.pictureInPictureControllerWillStopPictureInPicture?(pictureInPictureController)
    }
    
    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        self.pipDelegate?.pictureInPictureControllerDidStopPictureInPicture?(pictureInPictureController)
    }
    
    func picture(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        self.pipDelegate?.picture?(pictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler: completionHandler)
    }

    // MARK: IMAWebOpenerDelegate
    
    func webOpenerWillOpenExternalBrowser(_ webOpener: NSObject!) {
        self.delegate?.adsPlugin?(self, webOpenerWillOpenExternalBrowser: webOpener)
    }
    
    func webOpenerWillOpen(inAppBrowser webOpener: NSObject!) {
        self.delegate?.adsPlugin?(self, webOpenerWillOpenInAppBrowser: webOpener)
    }
    
    func webOpenerDidOpen(inAppBrowser webOpener: NSObject!) {
        self.delegate?.adsPlugin?(self, webOpenerDidOpenInAppBrowser: webOpener)
    }
    
    func webOpenerWillClose(inAppBrowser webOpener: NSObject!) {
        self.delegate?.adsPlugin?(self, webOpenerWillCloseInAppBrowser: webOpener)
    }
    
    func webOpenerDidClose(inAppBrowser webOpener: NSObject!) {
        self.delegate?.adsPlugin?(self, webOpenerDidCloseInAppBrowser: webOpener)
    }
}
