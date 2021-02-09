// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import UIKit
import AVFoundation

/// A simple `UIView` subclass that is backed by an `AVPlayerLayer` layer.
@objc public class PlayerView: UIView {
    
    @objc public var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }
    
    public override var contentMode: UIView.ContentMode {
        didSet {
            switch self.contentMode {
            case .scaleAspectFill:
                playerLayer.videoGravity = .resizeAspectFill
            case .scaleAspectFit:
                playerLayer.videoGravity = .resizeAspect
            case .scaleToFill:
                playerLayer.videoGravity = .resize
            default:
                playerLayer.videoGravity = .resizeAspect
            }
        }
    }
    
    var playerLayer: AVPlayerLayer {
        return self.layer as! AVPlayerLayer
    }
    
    // Override UIView property
    override public static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    /// adds the player view as a subview to the container view and sets up constraints
    @objc public func add(toContainer container: UIView) {
        self.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(self)
        
        let views = ["playerView": self]
        
        let horizontalConstraint = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[playerView]-0-|", options: [], metrics: nil, views: views)
        let verticalConstraint = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[playerView]-0-|", options: [], metrics: nil, views: views)
        
        container.addConstraints(horizontalConstraint)
        container.addConstraints(verticalConstraint)
    }
    
    /// creates a new `PlayerView` instance and connects it to the player
    /// - important: make sure to keep strong reference for the player view instance (either from adding as subview or property),
    /// otherwise it will be deallocated as the framework holds a weak reference to it
    @objc public static func createPlayerView(forPlayer player: Player) -> PlayerView {
        let playerView = PlayerView()
        player.view = playerView
        return playerView
    }
}
