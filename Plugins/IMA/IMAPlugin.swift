//
//  IMAPlugin.swift
//  AdvancedExample
//
//  Created by Vadim Kononov on 19/10/2016.
//  Copyright © 2016 Google, Inc. All rights reserved.
//

import GoogleInteractiveMediaAds

extension IMAAdsManager {
    func getAdCuePoints() -> PKAdCuePoints {
        return PKAdCuePoints(cuePoints: self.adCuePoints as? [TimeInterval] ?? [])
    }
}

extension PKAdInfo {
    convenience init(ad: IMAAd) {
        self.init(
            adDescription: ad.adDescription,
            adDuration: ad.duration,
            title: ad.adTitle,
            isSkippable: ad.isSkippable,
            contentType: ad.contentType,
            adId: ad.adId,
            adSystem: ad.adSystem,
            height: Int(ad.height),
            width: Int(ad.width),
            podCount: Int(ad.adPodInfo.totalAds),
            podPosition: Int(ad.adPodInfo.adPosition),
            podTimeOffset: ad.adPodInfo.timeOffset
        )
    }
}

@objc public class IMAPlugin: BasePlugin, PKPluginWarmUp, PlayerDecoratorProvider, AdsPlugin, IMAAdsLoaderDelegate, IMAAdsManagerDelegate, IMAWebOpenerDelegate, IMAContentPlayhead {
    
    weak var dataSource: AdsPluginDataSource? {
        didSet {
            PKLog.debug("data source set")
        }
    }
    weak var delegate: AdsPluginDelegate?
    weak var pipDelegate: AVPictureInPictureControllerDelegate?
    
    private var adsManager: IMAAdsManager?
    private var renderingSettings: IMAAdsRenderingSettings! = IMAAdsRenderingSettings()
    private static var loader: IMAAdsLoader!
    
    private var pictureInPictureProxy: IMAPictureInPictureProxy?
    private var loadingView: UIView?
    // we must have config error will be thrown otherwise
    private var config: AdsConfig!
    
    private var isAdPlayback = false
    private var startAdCalled = false
    private var loaderFailed = false
    
    /************************************************************/
    // MARK: - IMAContentPlayhead
    /************************************************************/
    
    public var currentTime: TimeInterval {
        // IMA must receive a number value so we must check `isNaN` on any value we send.
        // Before returning `player.currentTime` we need to check `!player.currentTime.isNaN`.
        if let currentTime = self.player?.currentTime, !currentTime.isNaN {
            return currentTime
        }
        return 0
    }
    
    /************************************************************/
    // MARK: - PKWarmUpProtocol
    /************************************************************/
    
    public static func warmUp() {
        // load adsLoader in order to make IMA download the needed objects before initializing.
        // will setup the instance when first player is loaded
        let imaSettings: IMASettings = IMASettings()
        let imaLoader = IMAAdsLoader(settings: imaSettings)
    }
    
    /************************************************************/
    // MARK: - PKPlugin
    /************************************************************/
    
    public override class var pluginName: String { return "IMAPlugin" }
    
    public required init(player: Player, pluginConfig: Any?, messageBus: MessageBus) throws {
        try super.init(player: player, pluginConfig: pluginConfig, messageBus: messageBus)
        if let adsConfig = pluginConfig as? AdsConfig {
            self.config = adsConfig
            if IMAPlugin.loader == nil {
                self.setupLoader(with: adsConfig)
            }
            
            IMAPlugin.loader.contentComplete()
            IMAPlugin.loader.delegate = self
        } else {
            PKLog.error("missing plugin config")
            throw PKPluginError.missingPluginConfig(pluginName: IMAPlugin.pluginName)
        }
        
        self.messageBus?.addObserver(self, events: [PlayerEvent.ended]) { [weak self] event in
            self?.contentComplete()
        }
    }
    
    public override func onUpdateConfig(pluginConfig: Any) {
        PKLog.debug("pluginConfig: " + String(describing: pluginConfig))
        
        super.onUpdateConfig(pluginConfig: pluginConfig)
        
        if let adsConfig = pluginConfig as? AdsConfig {
            self.config = adsConfig
        }
    }
    
    // TODO:: finilize update config & updateMedia logic
    public override func onUpdateMedia(mediaConfig: MediaConfig) {
        PKLog.debug("mediaConfig: " + String(describing: mediaConfig))
        super.onUpdateMedia(mediaConfig: mediaConfig)
    }
    
    public override func destroy() {
        super.destroy()
        self.destroyManager()
    }
    
    /************************************************************/
    // MARK: - PlayerDecoratorProvider
    /************************************************************/
    
    public func getPlayerDecorator() -> PlayerDecoratorBase? {
        return AdsEnabledPlayerController(adsPlugin: self)
    }
    
    /************************************************************/
    // MARK: - AdsPlugin
    /************************************************************/
    
    func requestAds() {
        guard let playerView = player?.view else { return }
        
        if self.config.adTagUrl != nil && self.config.adTagUrl != "" {
            self.startAdCalled = false
            
            // setup ad display container and companion if exists, needs to create a new ad container for each request.
            var companionAdSlot: IMACompanionAdSlot? = nil
            let adDisplayContainer: IMAAdDisplayContainer
            if let companionView = self.config?.companionView {
                companionAdSlot = IMACompanionAdSlot(view: companionView, width: Int32(companionView.frame.size.width), height: Int32(companionView.frame.size.height))
                adDisplayContainer = IMAAdDisplayContainer(adContainer: playerView, companionSlots: [companionAdSlot!])
            } else {
                adDisplayContainer = IMAAdDisplayContainer(adContainer: playerView, companionSlots: [])
            }
            
            var request: IMAAdsRequest
            request = IMAAdsRequest(adTagUrl: self.config.adTagUrl, adDisplayContainer: adDisplayContainer, contentPlayhead: self, userContext: nil)
            
            IMAPlugin.loader.requestAds(with: request)
            PKLog.trace("request Ads")
        }
    }
    
    @discardableResult
    func start(showLoadingView: Bool) -> Bool {
        if self.loaderFailed {
            return false
        }
        
        if self.config.adTagUrl != nil && self.config.adTagUrl != "" {
            if showLoadingView {
                self.showLoadingView(true, alpha: 1)
            }
            
            if let adsManager = self.adsManager {
                adsManager.initialize(with: self.renderingSettings)
                self.notifyAdCuePoints(fromAdsManager: adsManager)
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
        IMAPlugin.loader.contentComplete()
    }
    
    /************************************************************/
    // MARK: - Private
    /************************************************************/
    
    private func setupLoader(with config: AdsConfig) {
        let imaSettings: IMASettings! = IMASettings()
        imaSettings.language = config.language
        imaSettings.enableBackgroundPlayback = config.enableBackgroundPlayback
        imaSettings.autoPlayAdBreaks = config.autoPlayAdBreaks
        IMAPlugin.loader = IMAAdsLoader(settings: imaSettings)
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
        
        if let videoView = self.player?.view {
            videoView.addSubview(self.loadingView!)
            videoView.addConstraint(NSLayoutConstraint(item: videoView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self.loadingView!, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0))
            videoView.addConstraint(NSLayoutConstraint(item: videoView, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: self.loadingView!, attribute: NSLayoutAttribute.left, multiplier: 1, constant: 0))
            videoView.addConstraint(NSLayoutConstraint(item: videoView, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self.loadingView!, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: 0))
            videoView.addConstraint(NSLayoutConstraint(item: videoView, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: self.loadingView!, attribute: NSLayoutAttribute.right, multiplier: 1, constant: 0))
        }
    }
    
    private func createRenderingSettings() {
        self.renderingSettings.webOpenerDelegate = self
        if let webOpenerPresentingController = self.config?.webOpenerPresentingController {
            self.renderingSettings.webOpenerPresentingController = webOpenerPresentingController
        }
        if let bitrate = self.config?.videoBitrate {
            self.renderingSettings.bitrate = bitrate
        }
        if let mimeTypes = self.config?.videoMimeTypes {
            self.renderingSettings.mimeTypes = mimeTypes
        }
    }
    
    private func showLoadingView(_ show: Bool, alpha: CGFloat) {
        if self.loadingView == nil {
            self.setupLoadingView()
        }
        
        self.loadingView!.alpha = alpha
        self.loadingView!.isHidden = !show

        self.player?.view?.bringSubview(toFront: self.loadingView!)
    }

    private func notify(event: AdEvent) {
        self.delegate?.adsPlugin(self, didReceive: event)
        self.messageBus?.post(event)
    }
    
    private func notifyAdCuePoints(fromAdsManager adsManager: IMAAdsManager) {
        // send ad cue points if exists and request is url type
        let adCuePoints = adsManager.getAdCuePoints()
        if self.config.adTagUrl != nil && adCuePoints.count > 0 {
            self.notify(event: AdEvent.AdCuePointsUpdate(adCuePoints: adCuePoints))
        }
    }
    
    func destroyManager() {
        self.isAdPlayback = false
        self.startAdCalled = false
        self.loaderFailed = false
        self.adsManager?.delegate = nil
        self.adsManager?.destroy()
        // In order to make multiple ad requests, AdsManager instance should be destroyed, and then contentComplete() should be called on AdsLoader.  
        // This will "reset" the SDK.
        self.contentComplete()
        self.adsManager = nil
    }
   
    /************************************************************/
    // MARK: - AdsLoaderDelegate
    /************************************************************/
    
    public func adsLoader(_ loader: IMAAdsLoader!, adsLoadedWith adsLoadedData: IMAAdsLoadedData!) {
        self.loaderFailed = false
        
        self.adsManager = adsLoadedData.adsManager
        adsLoadedData.adsManager.delegate = self
        self.createRenderingSettings()
        
        if self.startAdCalled {
            self.adsManager!.initialize(with: self.renderingSettings)
            self.notifyAdCuePoints(fromAdsManager: self.adsManager!)
        }
        PKLog.debug("ads manager set")
    }
    
    public func adsLoader(_ loader: IMAAdsLoader!, failedWith adErrorData: IMAAdLoadingErrorData!) {
        self.loaderFailed = true
        self.showLoadingView(false, alpha: 0)
        PKLog.error(adErrorData.adError.message)
        self.messageBus?.post(AdEvent.Error(nsError: IMAPluginError(adError: adErrorData.adError).asNSError))
        self.delegate?.adsPlugin(self, loaderFailedWith: adErrorData.adError.message)
    }
    
    /************************************************************/
    // MARK: - AdsManagerDelegate
    /************************************************************/
    
    public func adsManagerAdDidStartBuffering(_ adsManager: IMAAdsManager!) {
        self.showLoadingView(true, alpha: 0.1)
    }
    
    public func adsManagerAdPlaybackReady(_ adsManager: IMAAdsManager!) {
        self.showLoadingView(false, alpha: 0)
    }
    
    public func adsManager(_ adsManager: IMAAdsManager!, didReceive event: IMAAdEvent!) {
        PKLog.debug("ads manager event: " + String(describing: event))
        switch event.type {
        // Ad break, will be called before each scheduled ad break. Ad breaks may contain more than 1 ad.
        case .AD_BREAK_READY:
            self.notify(event: AdEvent.AdBreakReady())
            let canPlay = self.dataSource?.adsPluginShouldPlayAd(self)
            if canPlay == nil || canPlay == true {
                adsManager.start()
            }
        case .LOADED:
            self.notify(event: AdEvent.AdLoaded())
            // single ad only fires `LOADED` without `AD_BREAK_READY`. 
            // if we have more than one ad don't handle the event, it will be handled in `AD_BREAK_READY`
            if adsManager.adCuePoints.count == 0 {
                let canPlay = self.dataSource?.adsPluginShouldPlayAd(self)
                if canPlay == nil || canPlay == true {
                    adsManager.start()
                } else {
                    adsManager.skip()
                    self.adsManagerDidRequestContentResume(adsManager)
                }
            }
        case .STARTED:
            let event = event.ad != nil ? AdEvent.AdStarted(adInfo: PKAdInfo(ad: event.ad)) : AdEvent.AdStarted()
            self.notify(event: event)
            self.showLoadingView(false, alpha: 0)
        case .AD_BREAK_STARTED:
            self.notify(event: AdEvent.AdBreakStarted())
            self.showLoadingView(false, alpha: 0)
        case .AD_BREAK_ENDED: self.notify(event: AdEvent.AdBreakEnded())
        case .ALL_ADS_COMPLETED:
            // detaching the delegate and destroying the adsManager. 
            // means all ads have been played so we can destroy the adsManager.
            self.destroyManager()
            self.notify(event: AdEvent.AllAdsCompleted())
        case .CLICKED: self.notify(event: AdEvent.AdClicked())
        case .COMPLETE: self.notify(event: AdEvent.AdComplete())
        case .CUEPOINTS_CHANGED: self.notify(event: AdEvent.AdCuePointsUpdate(adCuePoints: adsManager.getAdCuePoints()))
        case .FIRST_QUARTILE: self.notify(event: AdEvent.AdFirstQuartile())
        case .LOG: self.notify(event: AdEvent.AdLog())
        case .MIDPOINT: self.notify(event: AdEvent.AdMidpoint())
        case .PAUSE: self.notify(event: AdEvent.AdPaused())
        case .RESUME: self.notify(event: AdEvent.AdResumed())
        case .SKIPPED: self.notify(event: AdEvent.AdSkipped())
        case .STREAM_LOADED: self.notify(event: AdEvent.AdStreamLoaded())
        case .TAPPED: self.notify(event: AdEvent.AdTapped())
        case .THIRD_QUARTILE: self.notify(event: AdEvent.AdThirdQuartile())
        }
    }
    
    public func adsManager(_ adsManager: IMAAdsManager!, didReceive error: IMAAdError!) {
        self.showLoadingView(false, alpha: 0)
        PKLog.error(error.message)
        self.messageBus?.post(AdEvent.Error(nsError: IMAPluginError(adError: error).asNSError))
        self.delegate?.adsPlugin(self, managerFailedWith: error.message)
    }
    
    public func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager!) {
        self.isAdPlayback = true
        self.notify(event: AdEvent.AdDidRequestPause())
    }
    
    public func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager!) {
        self.isAdPlayback = false
        self.showLoadingView(false, alpha: 0)
        self.notify(event: AdEvent.AdDidRequestResume())
    }
    
    public func adsManager(_ adsManager: IMAAdsManager!, adDidProgressToTime mediaTime: TimeInterval, totalTime: TimeInterval) {
        self.notify(event: AdEvent.AdDidProgressToTime(mediaTime: mediaTime, totalTime: totalTime))
    }
    
    /************************************************************/
    // MARK: - AVPictureInPictureControllerDelegate
    /************************************************************/
    
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

    /************************************************************/
    // MARK: - IMAWebOpenerDelegate
    /************************************************************/
    
    public func webOpenerWillOpenExternalBrowser(_ webOpener: NSObject) {
        self.notify(event: AdEvent.AdWebOpenerWillOpenExternalBrowser(webOpener: webOpener))
    }
    
    public func webOpenerWillOpen(inAppBrowser webOpener: NSObject!) {
        self.notify(event: AdEvent.AdWebOpenerWillOpenInAppBrowser(webOpener: webOpener))
    }
    
    public func webOpenerDidOpen(inAppBrowser webOpener: NSObject!) {
        self.notify(event: AdEvent.AdWebOpenerDidOpenInAppBrowser(webOpener: webOpener))
    }
    
    public func webOpenerWillClose(inAppBrowser webOpener: NSObject!) {
        self.notify(event: AdEvent.AdWebOpenerWillCloseInAppBrowser(webOpener: webOpener))
    }
    
    public func webOpenerDidClose(inAppBrowser webOpener: NSObject!) {
        self.notify(event: AdEvent.AdWebOpenerDidCloseInAppBrowser(webOpener: webOpener))
    }
}
