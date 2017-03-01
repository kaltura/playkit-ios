//
//  IMAPlugin.swift
//  AdvancedExample
//
//  Created by Vadim Kononov on 19/10/2016.
//  Copyright © 2016 Google, Inc. All rights reserved.
//

import GoogleInteractiveMediaAds

/************************************************************/
// MARK: - IMAPluginError
/************************************************************/

/// `IMAPluginError` used to wrap an `IMAAdError` and provide converation to `NSError`
struct IMAPluginError: PKError {
    
    var adError: IMAAdError
    
    static let Domain = "com.kaltura.playkit.error.ima"
    
    var code: Int {
        return adError.code.rawValue
    }
    
    var errorDescription: String {
        return adError.message
    }
    
    var userInfo: [String: Any] {
        return [
            PKErrorKeys.ErrorTypeKey : adError.type.rawValue
        ]
    }
}

// IMA plugin error userInfo keys.
extension PKErrorKeys {
    static let ErrorTypeKey = "errorType"
}

extension PKErrorDomain {
    @objc public static let IMA = IMAPluginError.Domain
}

/************************************************************/
// MARK: - IMAPlugin
/************************************************************/

@objc public class IMAPlugin: BasePlugin, PlayerDecoratorProvider, AdsPlugin, IMAAdsLoaderDelegate, IMAAdsManagerDelegate, IMAWebOpenerDelegate, IMAContentPlayhead {

    private unowned var messageBus: MessageBus
    
    weak var dataSource: AdsPluginDataSource? {
        didSet {
            PKLog.debug("data source set")
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
    
    private var config: AdsConfig?
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
    
    private var timer: Timer?
    
    public var currentTime: TimeInterval {
        return self.currentPlaybackTime
    }
    
    /************************************************************/
    // MARK: - PKPlugin
    /************************************************************/
    
    public override required init(player: Player, pluginConfig: Any?, messageBus: MessageBus) {
        self.messageBus = messageBus
        super.init(player: player, pluginConfig: pluginConfig, messageBus: messageBus)
        if let adsConfig = pluginConfig as? AdsConfig {
            self.config = adsConfig
            if IMAPlugin.loader == nil {
                self.setupLoader(with: adsConfig)
            }
            
            IMAPlugin.loader.contentComplete()
            IMAPlugin.loader.delegate = self
            
            if let adTagUrl = adsConfig.adTagUrl {
                self.adTagUrl = adTagUrl
            } else if let adTagsTimes = adsConfig.tagsTimes {
                self.tagsTimes = adTagsTimes
                self.sortedTagsTimes = adTagsTimes.keys.sorted()
            }
        } else {
            PKLog.error("missing plugin config")
        }
        
        self.messageBus.addObserver(self, events: [PlayerEvent.ended], block: { (data: Any) -> Void in
            self.contentComplete()
        })
        
        self.timer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(IMAPlugin.update), userInfo: nil, repeats: true)
    }
    
    public override class var pluginName: String { return "IMAPlugin" }
    
    public override func destroy() {
        super.destroy()
        self.destroyManager()
        self.timer?.invalidate()
    }
    
    /************************************************************/
    // MARK: - Internal
    /************************************************************/
    
    func getPlayerDecorator() -> PlayerDecoratorBase? {
        return AdsEnabledPlayerController(adsPlugin: self)
    }
    
    func requestAds() {
        if self.adTagUrl != nil && self.adTagUrl != "" {
            self.startAdCalled = false
            
            var request: IMAAdsRequest
            request = IMAAdsRequest(adTagUrl: self.adTagUrl, adDisplayContainer: self.createAdDisplayContainer(), contentPlayhead: self, userContext: nil)
            
            IMAPlugin.loader.requestAds(with: request)
            PKLog.trace("request Ads")
        }
    }
    
    @discardableResult
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

    private func setupMainView() {
//        if let _ = self.player.playerEngine {
//            self.pictureInPictureProxy = IMAPictureInPictureProxy(avPictureInPictureControllerDelegate: self)
//        }
        
        if let companionView = self.config?.companionView {
            self.companionSlot = IMACompanionAdSlot(view: companionView, width: Int32(companionView.frame.size.width), height: Int32(companionView.frame.size.height))
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
        return IMAAdDisplayContainer(adContainer: self.player.view, companionSlots: self.config?.companionView != nil ? [self.companionSlot!] : nil)
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
            let currentTime = self.player.currentTime
            if currentTime.isNaN {
                return
            }
            self.currentPlaybackTime = currentTime
            self.loadAdsIfNeeded()
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

        self.player.view?.bringSubview(toFront: self.loadingView!)
    }
    
    private func convertToPlayerEvent(_ event: IMAAdEventType) -> AdEvent.Type {
        switch event {
        case .AD_BREAK_READY:
            return AdEvent.adBreakReady
        case .AD_BREAK_ENDED:
            return AdEvent.adBreakEnded
        case .AD_BREAK_STARTED:
            return AdEvent.adBreakStarted
        case .ALL_ADS_COMPLETED:
            return AdEvent.adAllCompleted
        case .CLICKED:
            return AdEvent.adClicked
        case .COMPLETE:
            return AdEvent.adComplete
        case .CUEPOINTS_CHANGED:
            return AdEvent.adCuepointsChanged
        case .FIRST_QUARTILE:
            return AdEvent.adFirstQuartile
        case .LOADED:
            return AdEvent.adLoaded
        case .LOG:
            return AdEvent.adLog
        case .MIDPOINT:
            return AdEvent.adMidpoint
        case .PAUSE:
            return AdEvent.adPaused
        case .RESUME:
            return AdEvent.adResumed
        case .SKIPPED:
            return AdEvent.adSkipped
        case .STARTED:
            return AdEvent.adStarted
        case .STREAM_LOADED:
            return AdEvent.adStreamLoaded
        case .TAPPED:
            return AdEvent.adTapped
        case .THIRD_QUARTILE:
            return AdEvent.adThirdQuartile
        }
    }

    private func notify(event: AdEvent) {
        self.delegate?.adsPlugin(self, didReceive: event)
        self.messageBus.post(event)
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
        
        PKLog.trace("ads manager set")
    }
    
    public func adsLoader(_ loader: IMAAdsLoader!, failedWith adErrorData: IMAAdLoadingErrorData!) {
        self.loaderFailed = true
        self.showLoadingView(false, alpha: 0)
        PKLog.error(adErrorData.adError.message)
        self.messageBus.post(AdEvent.Error(nsError: IMAPluginError(adError: adErrorData.adError).asNSError))
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
        
        switch event.type {
        case .AD_BREAK_READY:
            let canPlay = self.dataSource?.adsPluginShouldPlayAd(self)
            if canPlay == nil || canPlay == true {
                adsManager.start()
            }
            break
        case .LOADED:
            if adsManager.adCuePoints.count == 0 { //single ad
                let canPlay = self.dataSource?.adsPluginShouldPlayAd(self)
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
        self.notify(event: event)
        PKLog.debug("ads manager event: " + String(describing: converted))
    }
    
    public func adsManager(_ adsManager: IMAAdsManager!, didReceive error: IMAAdError!) {
        self.showLoadingView(false, alpha: 0)
        PKLog.error(error.message)
        self.messageBus.post(AdEvent.Error(nsError: IMAPluginError(adError: error).asNSError))
        self.delegate?.adsPlugin(self, managerFailedWith: error.message)
    }
    
    public func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager!) {
        self.notify(event: AdEvent.AdDidRequestPause())
        self.isAdPlayback = true
    }
    
    public func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager!) {
        self.showLoadingView(false, alpha: 0)
        self.notify(event: AdEvent.AdDidRequestResume())
        self.isAdPlayback = false
    }
    
    public func adsManager(_ adsManager: IMAAdsManager!, adDidProgressToTime mediaTime: TimeInterval, totalTime: TimeInterval) {
        var data = [String: TimeInterval]()
        data["mediaTime"] = mediaTime
        data["totalTime"] = totalTime
        self.notify(event: AdEvent.AdDidProgressToTime(mediaTime: mediaTime, totalTime: totalTime))
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
