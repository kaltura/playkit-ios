//
//  AVPlayerEngine.swift
//  Pods
//
//  Created by Eliza Sapir on 07/11/2016.
//
//

import Foundation
import AVFoundation


class AVPlayerEngine : AVPlayer, PlayerEngine {
    private var _layer: AVPlayerLayer!
    public var layer: CALayer! {
        get {
            return _layer
        }
    }
    
    /**
     Convenience method for setting shouldPlayWhenReady to true.
     */
    public func load() {
      
    }

    /// TODO::
    //private var asset: PlayerAsset?

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
        
    public override init() {
        super.init()
        _layer = AVPlayerLayer(player: self)
    }
    
    public var view: UIView? {
        get {
            return self.view
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
}

