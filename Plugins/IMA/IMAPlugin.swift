//
//  IMAPlugin.swift
//  AdvancedExample
//
//  Created by Vadim Kononov on 19/10/2016.
//  Copyright © 2016 Google, Inc. All rights reserved.
//

import GoogleInteractiveMediaAds

public class IMAPlugin: NSObject, AVPictureInPictureControllerDelegate, PlayerDecoratorProvider, AdsPlugin, IMAAdsLoaderDelegate, IMAAdsManagerDelegate, IMAWebOpenerDelegate, IMAContentPlayhead {

    private var player: Player!
    
    private var messageBus: MessageBus?
    
    weak var dataSource: AdsPluginDataSource! {
        didSet {
            self.setupMainView()
        }
    }
    weak var delegate: AdsPluginDelegate?
    weak var pipDelegate: AVPictureInPictureControllerDelegate?
    
    private var contentPlayhead: IMAAVPlayerContentPlayhead?
    private var manager: IMAAdsManager?
    private var companionSlot: IMACompanionAdSlot?
    private var renderingSettings: IMAAdsRenderingSettings! = IMAAdsRenderingSettings()
    private static var loader: IMAAdsLoader!
    
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
    private var loaderFailed = false
    
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
            return String(describing: IMAPlugin.self)
        }
    }
    
    public func load(player: Player, config: Any?, messageBus: MessageBus) {
        
        self.messageBus = messageBus
        
        if let adsConfig = config as? AdsConfig {
            self.config = adsConfig
            self.player = player
            
            if IMAPlugin.loader == nil {
                self.setupLoader(with: self.config)
            }
            
            IMAPlugin.loader.contentComplete()
            IMAPlugin.loader.delegate = self
            
            if let adTagUrl = self.config.adTagUrl {
                self.adTagUrl = adTagUrl
            } else if let adTagsTimes = self.config.tagsTimes {
                self.tagsTimes = adTagsTimes
            }
        }

        var events: [PKEvent.Type] = []
        events.append(PlayerEvents.ended)
        self.messageBus?.addObserver(self, events: events, block: { (data: Any) -> Void in
            self.contentComplete()
        })

        Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(IMAPlugin.update), userInfo: nil, repeats: true)
    }

    public func destroy() {
        self.destroyManager()
    }
    
    func getPlayerDecorator() -> PlayerDecoratorBase? {
        return AdsEnabledPlayerController(adsPlugin: self)
    }
    //MARK: public methods
    
    func requestAds() {
        if self.adTagUrl != nil && self.adTagUrl != "" {
            self.startAdCalled = false
            
            var request: IMAAdsRequest
            
//            if let avPlayer = self.player.playerEngine as? AVPlayer {
//                request = IMAAdsRequest(adTagUrl: self.adTagUrl, adDisplayContainer: self.createAdDisplayContainer(), avPlayerVideoDisplay: IMAAVPlayerVideoDisplay(avPlayer: avPlayer), pictureInPictureProxy: self.pictureInPictureProxy, userContext: nil)
//            } else {
                request = IMAAdsRequest(adTagUrl: self.adTagUrl, adDisplayContainer: self.createAdDisplayContainer(), contentPlayhead: self, userContext: nil)
//            }
            
            IMAPlugin.loader.requestAds(with: request)
        }
    }
    
    func start(showLoadingView: Bool) -> Bool {
        if self.loaderFailed {
            return false
        }
        
        if self.adTagUrl != nil && self.adTagUrl != "" {
            if showLoadingView {
                self.showLoadingView(true, alpha: 1)
            }
            
            if let manager = self.manager {
                manager.initialize(with: self.renderingSettings)
            } else {
                self.startAdCalled = true
            }
            return true
        }
        return false
    }
    
    func resume() {
        self.manager?.resume()
    }
    
    func pause() {
        self.manager?.pause()
    }
    
    func contentComplete() {
        IMAPlugin.loader.contentComplete()
    }
    
    //MARK: private methods
    
    private func setupLoader(with config: AdsConfig) {
        let imaSettings: IMASettings! = IMASettings()
        imaSettings.language = config.language
        imaSettings.enableBackgroundPlayback = config.enableBackgroundPlayback
        imaSettings.autoPlayAdBreaks = config.autoPlayAdBreaks
        
        IMAPlugin.loader = IMAAdsLoader(settings: imaSettings)
    }

    private func setupMainView() {
//        if let _ = self.player.playerEngine {
//            self.pictureInPictureProxy = IMAPictureInPictureProxy(avPictureInPictureControllerDelegate: self)
//        }
        
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
        self.renderingSettings.webOpenerDelegate = self
        if let webOpenerPresentingController = self.config.webOpenerPresentingController {
            self.renderingSettings.webOpenerPresentingController = webOpenerPresentingController
        }
        
        if let bitrate = self.config.videoBitrate {
            self.renderingSettings.bitrate = bitrate
        }
        if let mimeTypes = self.config.videoMimeTypes {
            self.renderingSettings.mimeTypes = mimeTypes
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
    
    private func convertToPlayerEvent(_ event: IMAAdEventType) -> AdEvents.Type {
        switch event {
        case .AD_BREAK_READY:
            return AdEvents.adBreakReady.self
        case .AD_BREAK_ENDED:
            return AdEvents.adBreakEnded.self
        case .AD_BREAK_STARTED:
            return AdEvents.adBreakStarted.self
        case .ALL_ADS_COMPLETED:
            return AdEvents.adAllCompleted.self
        case .CLICKED:
            return AdEvents.adClicked.self
        case .COMPLETE:
            return AdEvents.adComplete.self
        case .CUEPOINTS_CHANGED:
            return AdEvents.adCuepointsChanged.self
        case .FIRST_QUARTILE:
            return AdEvents.adFirstQuartile.self
        case .LOADED:
            return AdEvents.adLoaded.self
        case .LOG:
            return AdEvents.adLog.self
        case .MIDPOINT:
            return AdEvents.adMidpoint.self
        case .PAUSE:
            return AdEvents.adPaused.self
        case .RESUME:
            return AdEvents.adResumed.self
        case .SKIPPED:
            return AdEvents.adSkipped.self
        case .STARTED:
            return AdEvents.adStarted.self
        case .STREAM_LOADED:
            return AdEvents.adStreamLoaded.self
        case .TAPPED:
            return AdEvents.adTapped.self
        case .THIRD_QUARTILE:
            return AdEvents.adThirdQuartile.self
        }
    }

    private func destroyManager() {
        self.manager?.destroy()
        self.manager = nil
    }
    
    // MARK: AdsLoaderDelegate
    
    public func adsLoader(_ loader: IMAAdsLoader!, adsLoadedWith adsLoadedData: IMAAdsLoadedData!) {
        self.loaderFailed = false
        
        self.manager = adsLoadedData.adsManager
        self.manager!.delegate = self
        self.createRenderingSettings()
        
        if self.startAdCalled {
            self.manager!.initialize(with: self.renderingSettings)
        }
    }
    
    public func adsLoader(_ loader: IMAAdsLoader!, failedWith adErrorData: IMAAdLoadingErrorData!) {
        self.loaderFailed = true
        self.showLoadingView(false, alpha: 0)
        self.delegate?.adsPlugin(self, loaderFailedWith: adErrorData.adError.message)
    }
    
    // MARK: AdsManagerDelegate
    
    public func adsManagerAdDidStartBuffering(_ adsManager: IMAAdsManager!) {
        self.showLoadingView(true, alpha: 0.1)
    }
    
    public func adsManagerAdPlaybackReady(_ adsManager: IMAAdsManager!) {
        self.showLoadingView(false, alpha: 0)
    }
    
    public func adsManager(_ adsManager: IMAAdsManager!, didReceive event: IMAAdEvent!) {
        let converted = self.convertToPlayerEvent(event.type)
//        print("ads event " + String(describing: converted))
        
        switch event.type {
        case .AD_BREAK_READY:
            let canPlay = self.dataSource.adsPluginShouldPlayAd(self)
            if canPlay == nil || canPlay == true {
                adsManager.start()
            }
            break
        case .LOADED:
            if adsManager.adCuePoints.count == 0 { //single ad
                let canPlay = self.dataSource.adsPluginShouldPlayAd(self)
                if canPlay == nil || canPlay == true {
                    adsManager.start()
                } else {
                    adsManager.skip()
                    self.adsManagerDidRequestContentResume(adsManager)
                }
            }
            break
        case .AD_BREAK_STARTED, .STARTED:
            self.showLoadingView(false, alpha: 0)
            break
        default:
            break
        }
        
        let event = converted.init()
        self.delegate?.adsPlugin(self, didReceive: event)
        
        messageBus?.post(event)
    }
    
    public func adsManager(_ adsManager: IMAAdsManager!, didReceive error: IMAAdError!) {
        self.showLoadingView(false, alpha: 0)
        self.delegate?.adsPlugin(self, managerFailedWith: error.message)
    }
    
    public func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager!) {
        self.delegate?.adsPlugin(self, didReceive: AdEvents.adDidRequestPause())
        self.isAdPlayback = true
    }
    
    public func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager!) {
        self.showLoadingView(false, alpha: 0)
        self.delegate?.adsPlugin(self, didReceive: AdEvents.adDidRequestResume())
        self.isAdPlayback = false
    }
    
    public func adsManager(_ adsManager: IMAAdsManager!, adDidProgressToTime mediaTime: TimeInterval, totalTime: TimeInterval) {
        var data = [String : TimeInterval]()
        data["mediaTime"] = mediaTime
        data["totalTime"] = totalTime
        self.delegate?.adsPlugin(self, didReceive: AdEvents.adDidProgressToTime(mediaTime: mediaTime, totalTime: totalTime))
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
    
    public func webOpenerWillOpenExternalBrowser(_ webOpener: NSObject) {
        self.delegate?.adsPlugin(self, didReceive: AdEvents.adWebOpenerWillOpenExternalBrowser(webOpener: webOpener))
    }
    
    public func webOpenerWillOpen(inAppBrowser webOpener: NSObject!) {
        self.delegate?.adsPlugin(self, didReceive: AdEvents.adWebOpenerWillOpenInAppBrowser(webOpener: webOpener))
    }
    
    public func webOpenerDidOpen(inAppBrowser webOpener: NSObject!) {
        self.delegate?.adsPlugin(self, didReceive: AdEvents.adWebOpenerDidOpenInAppBrowser(webOpener: webOpener))
    }
    
    public func webOpenerWillClose(inAppBrowser webOpener: NSObject!) {
        self.delegate?.adsPlugin(self, didReceive: AdEvents.adWebOpenerWillCloseInAppBrowser(webOpener: webOpener))
    }
    
    public func webOpenerDidClose(inAppBrowser webOpener: NSObject!) {
        self.delegate?.adsPlugin(self, didReceive: AdEvents.adWebOpenerDidCloseInAppBrowser(webOpener: webOpener))
    }
}
