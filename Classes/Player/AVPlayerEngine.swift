//
//  AVPlayerEngine.swift
//  Pods
//
//  Created by Eliza Sapir on 07/11/2016.
//
//

import Foundation
import AVFoundation
import AVKit
import CoreMedia

class AVPlayerEngine : AVPlayer, PlayerEngine {
    
    private var avPlayerLayer: AVPlayerLayer!
    
    private var _view: PlayerView!
    var delegate: PlayerEngineDelegate?
    
    public var view: UIView! {
        get {
            return _view
        }
    }
    
    public var currentPosition: Double {
        get {
            return CMTimeGetSeconds(self.currentTime())
        }
        set {
            let newTime = CMTimeMakeWithSeconds(newValue, 1)
            super.seek(to: newTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
        }
    }
    
    public var duration: Double {
        guard let currentItem = self.currentItem else { return 0.0 }
        
        return CMTimeGetSeconds(currentItem.duration)
    }
    
    public var autoPlay: Bool = false {
        
        didSet {
            print("autoPlay has changed from \(oldValue) to \(autoPlay)")
            if autoPlay {
                self.play()
            } else {
                self.pause()
            }
        }
    }
    
    /// TODO::
    //private var asset: PlayerAsset?
    
    public override init() {
        super.init()
        avPlayerLayer = AVPlayerLayer(player: self)
        _view = PlayerView(playerLayer: avPlayerLayer)
    }
    
    /**
     Convenience method for setting shouldPlayWhenReady to true.
     */
    public func load() {
      
    }

    public override func pause() {
       // autoPlay = false
        
        if self.rate == 1.0 {
            // Playing, so pause.
            print("pause")
            super.pause()
        }
    }
    
    public override func play() {
       // autoPlay = true
        
        if self.rate != 1.0 {
            print("play")
            super.play()
        }
    }
    
    func prepareNext(_ config: PlayerConfig) -> Bool {
        if let sources = config.mediaEntry?.sources {
            if sources.count > 0 {
                if let contentUrl = sources[0].contentUrl {
                    self.replaceCurrentItem(with: AVPlayerItem(url: contentUrl))
                }
            }
        }
        return true
    }
    
    func loadNext() -> Bool {
        return false
    }
    
    func addBoundaryTimeObserver(origin: Origin, offset: TimeInterval, wait: Bool, observer: TimeObserver) {
        
    }
    
    func destroy() {
        
    }
    
    @available(iOS 9.0, *)
    func createPiPController(with delegate: AVPictureInPictureControllerDelegate) -> AVPictureInPictureController?{
        let pip = AVPictureInPictureController(playerLayer: avPlayerLayer)
        pip?.delegate = delegate
        return pip
    }
    
    // MARK: - KVO
    // KVO contexts
    private var PlayerObserverContext = 0
    private var PlayerItemObserverContext = 0
    private var PlayerLayerObserverContext = 0
    
    // KVO player keys
    private let PlayerTracksKey = "tracks"
    private let PlayerPlayableKey = "playable"
    private let PlayerDurationKey = "duration"
    private let PlayerRateKey = "rate"
    
    // KVO player item keys
    private let PlayerStatusKey = "status"
    private let PlayerEmptyBufferKey = "playbackBufferEmpty"
    private let PlayerKeepUpKey = "playbackLikelyToKeepUp"
    private let PlayerLoadedTimeRangesKey = "loadedTimeRanges"
    
    // KVO player layer keys
    private let PlayerReadyForDisplayKey = "readyForDisplay"
    
    // - Observers
    func addObservers() {
        self.addObserver(self, forKeyPath: PlayerRateKey, options: [], context: nil)
        
        self.currentItem?.addObserver(self, forKeyPath: PlayerEmptyBufferKey, options: [], context: nil)
        self.currentItem?.addObserver(self, forKeyPath: PlayerStatusKey, options: [], context: nil)
        
        NotificationCenter.default.addObserver(self, selector: Selector("playerFailed:"), name: NSNotification.Name.AVPlayerItemFailedToPlayToEndTime, object: self.currentItem)
        NotificationCenter.default.addObserver(self, selector: Selector("playerPlayedToEnd:"), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.currentItem)
    }
    
    func removeObservers() {
        self.removeObserver(self, forKeyPath: PlayerRateKey)
        
        self.currentItem?.removeObserver(self, forKeyPath: PlayerEmptyBufferKey)
        self.currentItem?.removeObserver(self, forKeyPath: PlayerStatusKey)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    override func observeValue(forKeyPath
        keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        if keyPath == "duration" {
            /*
             Handle `NSNull` value for `NSKeyValueChangeNewKey`, i.e. when
             `currentItem` is nil.
             */
            
            if let newDurationAsValue = change?[NSKeyValueChangeKey.newKey] as? NSValue {
                print("newDurationAsValue:" + String(describing: newDurationAsValue))
            } else if keyPath == PlayerRateKey {
                // Update `playPauseButton` image.
                
            }
        }
    }
}

